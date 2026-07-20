{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.desktop.dictate;
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [ sox curl jq wtype libnotify gopass coreutils ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
      pidfile="$state.pid"
      wavfile="$state.wav"

      clean=0
      if [ "''${1:-}" = "--clean" ]; then clean=1; fi

      notify() { notify-send -a Dictate -h string:x-canonical-private-synchronous:dictate -t "''${2:-2500}" "$1" || true; }

      if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        rec_pid="$(cat "$pidfile")"
        rm -f "$pidfile"
        sleep ${cfg.stopDelay}
        kill -INT "$rec_pid" 2>/dev/null || true
        tail --pid="$rec_pid" -f /dev/null 2>/dev/null || true

        notify "Transcribing…"
        key="$(gopass show -o ${cfg.gopassPath})"
        args=(-sS https://openrouter.ai/api/v1/audio/transcriptions
          -H "Authorization: Bearer $key"
          -F "file=@$wavfile"
          -F "model=${cfg.model}")
        ${optionalString (cfg.language != "") ''args+=(-F "language=${cfg.language}")''}
        text="$(curl "''${args[@]}" | jq -r '.text // empty')" || text=""
        rm -f "$wavfile"

        if [ -z "$text" ]; then
          notify "Dictate: no transcription"
          exit 0
        fi

        if [ "$clean" = 1 ]; then
          notify "Cleaning up…"
          sys=${escapeShellArg cfg.cleanupPrompt}
          # shellcheck disable=SC2016
          body="$(jq -n --arg m "${cfg.cleanupModel}" --arg sys "$sys" --arg u "$text" \
            '{model:$m, temperature:0, messages:[{role:"system",content:$sys},{role:"user",content:$u}]}')"
          cleaned="$(curl -sS https://openrouter.ai/api/v1/chat/completions \
            -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
            -d "$body" | jq -r '.choices[0].message.content // empty')" || cleaned=""
          if [ -n "$cleaned" ]; then text="$cleaned"; fi
        fi

        wtype -d ${cfg.typeDelay} -k Shift_L "$text"
      else
        rm -f "$pidfile" "$wavfile"
        rec -q -c 1 -r 16000 "$wavfile" &
        echo "$!" > "$pidfile"
        notify "🎙 Recording — press again to stop"
      fi
    '';
  };
in {
  options.modules.desktop.dictate = {
    enable = mkEnableOption "Push-to-toggle voice dictation via OpenRouter Whisper (types into the focused window)";

    model = mkOption {
      type = types.str;
      default = "openai/whisper-large-v3-turbo";
      description = "OpenRouter transcription model slug.";
    };

    language = mkOption {
      type = types.str;
      default = "";
      description = ''Force recognition language (e.g. "de"); empty = auto-detect.'';
    };

    gopassPath = mkOption {
      type = types.str;
      default = "cloud/openrouter/stt";
      description = "gopass entry holding the OpenRouter API key.";
    };

    stopDelay = mkOption {
      type = types.str;
      default = "0.8";
      description = ''
        Seconds to keep recording after the stop key is pressed, so the
        capture buffer's tail (last spoken word) is flushed before sox stops.
      '';
    };

    typeDelay = mkOption {
      type = types.str;
      default = "12";
      description = ''
        Milliseconds between synthesized keystrokes (`wtype -d`). Raise if
        characters get dropped by the compositor.
      '';
    };

    cleanupModel = mkOption {
      type = types.str;
      default = "deepseek/deepseek-v4-flash";
      description = ''
        OpenRouter chat model used to clean up the raw transcript when
        `dictate --clean` is invoked.
      '';
    };

    cleanupPrompt = mkOption {
      type = types.str;
      default = "You are a transcription cleanup tool. The user message is raw speech-to-text output. Fix spelling, punctuation, capitalization and obvious recognition errors. Preserve the original wording, meaning and language exactly — do not translate, summarize, answer or add anything. Output only the corrected text.";
      description = "System prompt for the cleanup model.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ dictate ];
  };
}
