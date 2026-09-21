{ config, lib, pkgs, hostname, ... }:
with lib;
let
  vars = import ./../../../../hosts/${hostname}/variables.nix;

  # No defaults on purpose, see README.md.
  dictation =
    vars.dictation
      or (throw "modules.desktop.dictate: no `dictation` block in hosts/${hostname}/variables.nix");
  require =
    name:
    dictation.${name}
      or (throw "modules.desktop.dictate: `dictation.${name}` is not set in hosts/${hostname}/variables.nix");

  cfg = config.modules.desktop.dictate;

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [ sox curl jq wtype libnotify gopass coreutils util-linux wl-clipboard cliphist hyprland pipewire ];
    text = ''
      export DICTATE_SPEECH_MODEL=${escapeShellArg (require "sttModel")}
      export DICTATE_CLEANUP_MODEL=${escapeShellArg (require "cleanupModel")}
      export DICTATE_GOPASS_PATH=${escapeShellArg cfg.gopassPath}
      export DICTATE_STOP_DELAY=${escapeShellArg cfg.stopDelay}
      export DICTATE_RESTORE_DELAY=${escapeShellArg cfg.restoreDelay}
      export DICTATE_MAX_SECONDS=${escapeShellArg cfg.maxSeconds}
      export DICTATE_TERMINAL_CLASSES=${escapeShellArg (concatStringsSep "\n" cfg.terminalClasses)}
      export DICTATE_CLEANUP_FALLBACK_MODELS=${escapeShellArg (concatStringsSep "\n" (require "cleanupFallbackModels"))}
      export DICTATE_CLEANUP_PROVIDERS=${escapeShellArg (concatStringsSep "\n" (require "cleanupProviders"))}
      export DICTATE_CLEANUP_PROMPT=${escapeShellArg cfg.cleanupPrompt}
    '' + builtins.readFile ./dictate.sh;
  };
in {
  options.modules.desktop.dictate = {
    enable = mkEnableOption "Push-to-toggle voice dictation via OpenRouter (pastes into the focused window)";

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

    maxSeconds = mkOption {
      type = types.str;
      default = "600";
      description = ''
        Hard cap on a single recording, in seconds. Only reached when the stop
        press is forgotten — rec then ends itself instead of filling tmpfs, and
        the next press starts a fresh recording. What was recorded is dropped,
        not transcribed.
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
      default = ''
      You are a transcription cleanup tool. The user message is raw speech-to-text output.
      Fix spelling, punctuation, capitalization and obvious recognition errors.
      Recurring proper nouns: Claude, Claude Code, NixOS, Hyprland, Home Manager, agenix, OpenRouter, Forgejo, Obsidian, Vikunja, Proxmox, Ansible, WireGuard, DynDNS, UniFi, Voxtral, Mistral, CHECK24, K3s, Rancher, HAProxy, Ghostty, MCP, Hetzner, Anthropic, Fable, Vorstellungsgespräch. When a word closely resembles one of these, it is that term and should be spelled accordingly. The speaker talks about the AI assistant Claude constantly; a transcribed 'Cloud' or 'cloud' is almost always 'Claude' and should only stay 'Cloud' when the sentence is clearly about cloud computing or a cloud provider. The speaker also has a speech habit of starting sentences with a reflexive filler word that carries no meaning, such as 'Ja', 'Also', 'Äh' or 'Öh' — remove such a filler word when it opens a sentence, unless it is doing real work (e.g. 'Ja' as an actual answer to a question, or 'Also' introducing a conclusion). The speaker also throws in standalone reflexive filler phrases such as 'Keine Ahnung.' as a complete sentence with no meaning of its own — remove such a sentence when it stands alone, but keep the same words when they are part of a real sentence (e.g. 'Ich habe keine Ahnung, warum das so ist' stays untouched). Preserve the original wording, meaning and language exactly otherwise — do not translate, summarize, answer or add anything.
      Output only the corrected text.
      The speech model regularly mishears two names: Forgejo as '4Geo', 'ForGeo', 'Fodjeo' or 'Frau Geo', and HowCanI as 'Hawk & Eye', 'HawkenEye', 'Hauk und Ei' or 'Haukenai'.
      Only replace a fragment that makes no sense as ordinary words where it stands; ordinary phrases such as 'for you' or 'how can I' stay unchanged, also inside a German sentence.
      Never drop a word or fragment you cannot place; keep it as is.
      '';
      description = ''
        System prompt for the cleanup model. Short-lived names go into
        ~/.config/dictate/vocabulary.txt instead, see README.md.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ dictate ];
  };
}
