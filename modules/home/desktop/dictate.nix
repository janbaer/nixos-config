{ config, lib, pkgs, hostname, ... }:
with lib;
let
  vars = import ./../../../hosts/${hostname}/variables.nix;

  # Deliberately no defaults. The models are configured once, in
  # hosts/common/variables.nix, and a missing entry has to fail the build rather
  # than fall back to something plausible. A default here would hide a typo in
  # the variables file, and that is precisely how the cleanup model went
  # unnoticed for days while every dictation quietly used a different one.
  dictation =
    vars.dictation
      or (throw "modules.desktop.dictate: no `dictation` block in hosts/${hostname}/variables.nix");
  requireModel =
    name:
    dictation.${name}
      or (throw "modules.desktop.dictate: `dictation.${name}` is not set in hosts/${hostname}/variables.nix");

  cfg = config.modules.desktop.dictate;

  # The script itself lives in dictate.sh instead of a Nix string: that keeps
  # shellcheck, syntax highlighting and `bash dictate.sh` available while
  # editing, and it removes the Nix-level branching that used to generate two
  # different scripts depending on how the transcript reached the window.
  #
  # Options are handed over as environment variables. writeShellApplication
  # concatenates this preamble with the file, so the exports are in place before
  # the script's own fallback defaults are evaluated.
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [ sox curl jq wtype libnotify gopass coreutils wl-clipboard cliphist hyprland pipewire ];
    text = ''
      export DICTATE_SPEECH_MODEL=${escapeShellArg (requireModel "sttModel")}
      export DICTATE_CLEANUP_MODEL=${escapeShellArg (requireModel "cleanupModel")}
      export DICTATE_LANGUAGE=${escapeShellArg cfg.language}
      export DICTATE_GOPASS_PATH=${escapeShellArg cfg.gopassPath}
      export DICTATE_STOP_DELAY=${escapeShellArg cfg.stopDelay}
      export DICTATE_RESTORE_DELAY=${escapeShellArg cfg.restoreDelay}
      export DICTATE_TERMINAL_CLASSES=${escapeShellArg (concatStringsSep "\n" cfg.terminalClasses)}
      export DICTATE_CLEANUP_PROMPT=${escapeShellArg cfg.cleanupPrompt}
    '' + builtins.readFile ./dictate.sh;
  };
in {
  options.modules.desktop.dictate = {
    enable = mkEnableOption "Push-to-toggle voice dictation via OpenRouter (pastes into the focused window)";

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

    terminalClasses = mkOption {
      type = types.listOf types.str;
      default = [ "com.mitchellh.ghostty" ];
      description = ''
        Window classes that paste with Ctrl+Shift+V instead of Ctrl+V.
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

    cleanupPrompt = mkOption {
      type = types.str;
      default = "You are a transcription cleanup tool. The user message is raw speech-to-text output. Fix spelling, punctuation, capitalization and obvious recognition errors. Recurring proper nouns: Claude, Claude Code, NixOS, Hyprland, Home Manager, agenix, OpenRouter, Forgejo, Obsidian, Vikunja, Proxmox, Ansible, WireGuard, DynDNS, UniFi, Voxtral, Mistral. When a word closely resembles one of these, it is that term and should be spelled accordingly. The speaker talks about the AI assistant Claude constantly; a transcribed 'Cloud' or 'cloud' is almost always 'Claude' and should only stay 'Cloud' when the sentence is clearly about cloud computing or a cloud provider. Preserve the original wording, meaning and language exactly — do not translate, summarize, answer or add anything. Output only the corrected text.";
      description = ''
        System prompt for the cleanup model.

        The proper-noun list comes from the debug log rather than guesswork: over
        80 dictations "Claude" arrived as "Cloud" nine times against seven
        correct ones, and "Voxtral" arrived as "VoxTrill" four times without ever
        being corrected. It only helps where the transcript still resembles the
        target word. "Environment-Variablen" came back as "Bayern-Programm" and
        "In-Wireman-Wire", and no list rescues that.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ dictate ];
  };
}
