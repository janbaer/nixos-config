{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
with lib;
let
  inherit (import ./../../../hosts/${hostname}/variables.nix)
    nodeVersion
    globalNpmPackages
    ;
  cfg = config.modules.dev.nodejs;

  # Turn a "name@version" / "@scope/name@version" / "name" spec from
  # globalNpmPackages into a { "npm:<name>" = "<version>"; } pair for mise's
  # tools table. A missing version defaults to "latest".
  toNpmTool =
    spec:
    let
      scoped = hasPrefix "@" spec;
      body = if scoped then removePrefix "@" spec else spec;
      parts = splitString "@" body;
      name = (optionalString scoped "@") + head parts;
      version = if length parts > 1 then last parts else "latest";
    in
    nameValuePair "npm:${name}" version;

  npmTools = listToAttrs (map toNpmTool globalNpmPackages);
in
{
  options.modules.dev.nodejs.enable = mkEnableOption "NodeJS with global packages";

  config = mkIf cfg.enable {
    programs.mise = {
      enable = true;
      enableZshIntegration = true;

      # Declarative global config. Home Manager renders this read-only at
      # ~/.config/mise/config.toml, so the installed tool set is a pure function
      # of this repo. Ad-hoc experiments go in a project-local mise.toml
      # (`mise use npm:foo`) or are run ephemerally (`mise exec`).
      globalConfig = {
        # Download prebuilt Node binaries instead of compiling from source.
        # mise defaults node.compile=true on NixOS (no FHS loader); nix-ld lets
        # the prebuilt binary run, so force the precompiled download.
        settings.node.compile = false;

        tools = {
          node = nodeVersion;
        }
        // npmTools;
      };
    };

    home.sessionPath = [
      "$HOME/.local/share/mise/shims"
    ];

    home.shellAliases = {
      yi = "yarn install --pure-lockfile";
      yl = "yarn lint";
      ys = "yarn start";
      yt = "yarn test";
      ytw = "yarn test:watch";
      yui = "yarn upgrade-interactive --latest";
      yd = "yarn debug";
    };

    # Materialize the declared tools. `mise install` only reads the config, so
    # it works against the read-only config.toml and is idempotent (it skips
    # already-installed versions).
    #
    # The HM activation runs with a minimal PATH. The npm backend needs `bash`
    # (npm's script-shell) and `mise` (mise's npm wrapper calls `mise` by name);
    # without them every npm tool fails with exit 127.
    home.activation.installing_nodejs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PATH="${lib.makeBinPath [ pkgs.bash pkgs.mise ]}:$PATH" \
        $DRY_RUN_CMD ${pkgs.mise}/bin/mise install
    '';
  };
}
