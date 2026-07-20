{
  description = "Cloud Whisper STT test shell (OpenRouter)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        dictate = pkgs.writeShellScriptBin "dictate" ''
          set -euo pipefail
          : "''${OPENROUTER_API_KEY:?OPENROUTER_API_KEY not set (gopass cloud/openrouter/stt)}"
          model="''${STT_MODEL:-openai/whisper-large-v3-turbo}"
          tmp="$(mktemp --suffix=.wav)"
          trap 'rm -f "$tmp"' EXIT

          echo "Recording — press Enter to stop..." >&2
          rec -q -c 1 -r 16000 "$tmp" &
          rec_pid=$!
          read -r || true
          kill -INT "$rec_pid" 2>/dev/null || true
          wait "$rec_pid" 2>/dev/null || true

          echo "Transcribing ($model)..." >&2
          args=(-sS https://openrouter.ai/api/v1/audio/transcriptions
            -H "Authorization: Bearer $OPENROUTER_API_KEY"
            -F "file=@$tmp" -F "model=$model")
          [ -n "''${STT_LANG:-}" ] && args+=(-F "language=$STT_LANG")
          curl "''${args[@]}" | jq -r '.text'
        '';
      in {
        default = pkgs.mkShellNoCC {
          packages = [pkgs.sox pkgs.curl pkgs.jq pkgs.gopass dictate];

          shellHook = ''
            if key=$(gopass show -o cloud/openrouter/stt 2>/dev/null); then
              export OPENROUTER_API_KEY="$key"
              echo "OPENROUTER_API_KEY loaded from gopass (cloud/openrouter/stt)."
            else
              echo "warn: gopass 'cloud/openrouter/stt' not found — store your key, then re-enter." >&2
            fi
            echo "Run 'dictate' to record + transcribe.  German: STT_LANG=de dictate"
          '';
        };
      }
    );
  };
}
