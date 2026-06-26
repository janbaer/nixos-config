{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.dev.hunk;

  hunkBin = pkgs.stdenv.mkDerivation rec {
    pname = "hunk";
    version = "0.16.0";

    src = pkgs.fetchurl {
      url = "https://github.com/modem-dev/hunk/releases/download/v${version}/hunkdiff-linux-x64.tar.gz";
      hash = "sha256-DdgMdnkmXfcmF4d6Atr+/WrGqDRSjhAldWdkLrLAXqY=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    # hunk is a Bun --compile single-file executable: the JS app is appended as a
    # trailer after the ELF and located by seeking from EOF. `strip` rewrites the
    # ELF and drops that trailer, leaving a bare Bun runtime. Keep it intact.
    dontStrip = true;

    # Install the full payload so `hunk skill path` resolves; symlink the binary
    # onto PATH. autoPatchelfHook still patches the real ELF under libexec.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/hunk $out/bin
      cp -r hunk metadata.json skills $out/libexec/hunk/
      ln -s $out/libexec/hunk/hunk $out/bin/hunk
      runHook postInstall
    '';
  };
in
{
  options.modules.dev.hunk.enable = mkEnableOption "hunk terminal diff viewer";

  config = mkIf cfg.enable {
    home.packages = [ hunkBin ];

    programs.git.settings = {
      core.pager = "${hunkBin}/bin/hunk pager";
      diff.tool = "hunk";
      difftool = {
        prompt = false;
        hunk.cmd = ''${hunkBin}/bin/hunk difftool "$LOCAL" "$REMOTE"'';
      };
      # `git review [base]` -> review current branch vs base (local PR-style diff).
      # ''${1:-main} is escaped so Nix doesn't antiquote the shell positional.
      alias.review = ''!f() { ${hunkBin}/bin/hunk diff "''${1:-main}...HEAD"; }; f'';
    };
  };
}
