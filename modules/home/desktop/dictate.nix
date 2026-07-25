{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.desktop.dictate;

  # The script itself lives in dictate.sh instead of a Nix string: that keeps
  # shellcheck, syntax highlighting and `bash dictate.sh` available while
  # editing, and it removes the Nix-level branching that used to generate two
  # different scripts depending on pasteMode.
  #
  # Options are handed over as environment variables. writeShellApplication
  # concatenates this preamble with the file, so the exports are in place before
  # the script's own fallback defaults are evaluated.
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [ sox curl jq wtype libnotify gopass coreutils wl-clipboard cliphist hyprland ];
    text = ''
      export DICTATE_SPEECH_MODEL=${escapeShellArg cfg.model}
      export DICTATE_CLEANUP_MODEL=${escapeShellArg cfg.cleanupModel}
      export DICTATE_LANGUAGE=${escapeShellArg cfg.language}
      export DICTATE_GOPASS_PATH=${escapeShellArg cfg.gopassPath}
      export DICTATE_STOP_DELAY=${escapeShellArg cfg.stopDelay}
      export DICTATE_RESTORE_DELAY=${escapeShellArg cfg.restoreDelay}
      export DICTATE_TYPE_DELAY=${escapeShellArg cfg.typeDelay}
      export DICTATE_PASTE_MODE=${escapeShellArg cfg.pasteMode}
      export DICTATE_TERMINAL_CLASSES=${escapeShellArg (concatStringsSep "\n" cfg.terminalClasses)}
      export DICTATE_CLEANUP_PROMPT=${escapeShellArg cfg.cleanupPrompt}
    '' + builtins.readFile ./dictate.sh;
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
