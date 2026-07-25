# Push-to-toggle dictation: one keybind starts the recording, the same keybind
# stops it, uploads the WAV to OpenRouter and puts the transcript into the
# focused window. State lives in a pidfile because the two presses are two
# independent process invocations — the second one has no shell context from
# the first.
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.desktop.dictate;

  # writeShellApplication (not writeShellScriptBin) buys two things we rely on:
  # `set -euo pipefail` and a PATH pinned to runtimeInputs. The pipefail part is
  # why nearly every command below carries an explicit `|| true` / `|| var=""` —
  # a failing notify-send or curl must not abort a recording session.
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [ sox curl jq wtype libnotify gopass coreutils wl-clipboard cliphist hyprland ];
    text = ''
      # XDG_RUNTIME_DIR is tmpfs, per-user and wiped on logout — recordings
      # never survive a session and never land on disk.
      state="''${XDG_RUNTIME_DIR:-/tmp}/dictate"
      pidfile="$state.pid"
      wavfile="$state.wav"

      clean=0
      if [ "''${1:-}" = "--clean" ]; then clean=1; fi

      # Env overrides let a single host try a different model without a rebuild;
      # once a model proves itself it moves into the host's home.nix.
      speech_model="''${DICTATION_SPEECH_MODEL:-${cfg.model}}"
      cleanup_model="''${DICTATION_CLEANUP_MODEL:-${cfg.cleanupModel}}"

      # x-canonical-private-synchronous replaces the previous dictate popup
      # instead of stacking a new one for every state change.
      notify() { notify-send -a Dictate -h string:x-canonical-private-synchronous:dictate -t "''${2:-2500}" "$1" || true; }

      if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        rec_pid="$(cat "$pidfile")"
        # Drop the pidfile before the delay: a stray second press during
        # transcription then starts a fresh recording instead of signalling a
        # pid that is already gone.
        rm -f "$pidfile"
        sleep ${cfg.stopDelay}
        # SIGINT, not SIGTERM — sox only writes the final WAV header on a clean
        # shutdown. A killed rec leaves a file the API rejects.
        kill -INT "$rec_pid" 2>/dev/null || true
        # rec is a child of the *first* invocation, so `wait` is unavailable
        # here; tail --pid blocks until that foreign pid exits.
        tail --pid="$rec_pid" -f /dev/null 2>/dev/null || true

        notify "Transcribing…"
        # Key is read per invocation instead of via agenix: dictation is
        # interactive anyway, so the gopass agent is unlocked and the key never
        # has to exist as a file in the Nix store or /run.
        key="$(gopass show -o ${cfg.gopassPath})"
        args=(-sS https://openrouter.ai/api/v1/audio/transcriptions
          -H "Authorization: Bearer $key"
          -F "file=@$wavfile"
          -F "model=$speech_model")
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
          # Build the request with jq -n --arg rather than string interpolation:
          # both the prompt and the transcript are arbitrary text and would
          # otherwise break the JSON on the first quote or newline.
          # shellcheck disable=SC2016
          body="$(jq -n --arg m "$cleanup_model" --arg sys "$sys" --arg u "$text" \
            '{model:$m, temperature:0, messages:[{role:"system",content:$sys},{role:"user",content:$u}]}')"
          cleaned="$(curl -sS https://openrouter.ai/api/v1/chat/completions \
            -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
            -d "$body" | jq -r '.choices[0].message.content // empty')" || cleaned=""
          if [ -n "$cleaned" ]; then text="$cleaned"; fi
        fi

        ${
          if cfg.pasteMode == "paste" then ''
            # Borrow the clipboard and hand it back afterwards. Only text is
            # preserved — an image on the clipboard is lost across a dictation.
            previous="$(wl-paste --no-newline 2>/dev/null || true)"
            printf '%s' "$text" | wl-copy --type text/plain

            # Terminals take Ctrl+Shift+V, everything else Ctrl+V, so the paste
            # shortcut depends on the class of the currently focused window.
            class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')" || class=""
            terminals=(${concatMapStringsSep " " escapeShellArg cfg.terminalClasses})
            shifted=0
            for t in "''${terminals[@]}"; do
              if [ "$class" = "$t" ]; then shifted=1; fi
            done

            if [ "$shifted" = 1 ]; then
              wtype -M ctrl -M shift -k v -m shift -m ctrl
            else
              wtype -M ctrl -k v -m ctrl
            fi

            sleep ${cfg.restoreDelay}

            # cliphist watches the clipboard, so the transcript ends up in the
            # clipboard history. Drop that entry again — but only if the newest
            # entry really is our text, otherwise we would delete whatever the
            # user copied in the meantime.
            entry="$(cliphist list 2>/dev/null | head -1 || true)"
            if [ -n "$entry" ] && [ "$(printf '%s\n' "$entry" | cliphist decode 2>/dev/null || true)" = "$text" ]; then
              printf '%s\n' "$entry" | cliphist delete
            fi

            if [ -n "$previous" ]; then
              printf '%s' "$previous" | wl-copy --type text/plain
            else
              wl-copy --clear
            fi
          '' else ''
            # Leading Shift_L is a throwaway keypress: the compositor needs a
            # moment to pick up wtype's freshly created virtual keyboard and
            # swallows whatever arrives first. Better a lost modifier than a
            # lost first character.
            wtype -d ${cfg.typeDelay} -k Shift_L "$text"
          ''
        }
      else
        # Clean up leftovers from a run that died between start and stop.
        rm -f "$pidfile" "$wavfile"
        # Mono 16 kHz is what Whisper resamples to internally — recording
        # anything richer only inflates the upload.
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

    pasteMode = mkOption {
      type = types.enum [ "paste" "type" ];
      default = "paste";
      description = ''
        How the transcript reaches the focused window. `paste` puts it on the
        clipboard and sends a single Ctrl+V; `type` synthesizes one keystroke
        per character via `wtype`.

        `type` drops characters on longer transcripts: wtype maps each needed
        character onto a limited set of virtual keycodes, so two adjacent
        characters sharing a keycode lose one of them. The effect scales with
        the number of distinct characters, which makes German text with
        umlauts the worst case.
      '';
    };

    terminalClasses = mkOption {
      type = types.listOf types.str;
      default = [ "com.mitchellh.ghostty" ];
      description = ''
        Window classes that paste with Ctrl+Shift+V instead of Ctrl+V. Only
        used when `pasteMode = "paste"`.
      '';
    };

    restoreDelay = mkOption {
      type = types.str;
      default = "0.5";
      description = ''
        Seconds to wait after Ctrl+V before restoring the previous clipboard
        contents, so the target window has finished reading the selection.
      '';
    };

    typeDelay = mkOption {
      type = types.str;
      default = "12";
      description = ''
        Milliseconds between synthesized keystrokes (`wtype -d`). Only used
        when `pasteMode = "type"`.
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
