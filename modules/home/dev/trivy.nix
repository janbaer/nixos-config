{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.modules.dev.trivy;

  trivyPackage =
    if cfg.version != null then
      pkgs.trivy.overrideAttrs (old: {
        version = cfg.version;
        src = old.src.override {
          rev = "v${cfg.version}";
          hash = cfg.srcHash;
        };
        vendorHash = cfg.vendorHash;
      })
    else
      pkgs.trivy;
in
{
  options.modules.dev.trivy = {
    enable = mkEnableOption "Trivy vulnerability scanner";

    version = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Override the trivy version. When set, srcHash and vendorHash must also be provided.";
      example = "0.68.2";
    };

    srcHash = mkOption {
      type = types.str;
      default = "";
      description = "SHA256 hash of the source archive for the overridden version.";
      example = "sha256-0s9N7BHLJOTnOfa9tQ70D5tfTDSEHsiLUYHpWZjuoEU=";
    };

    vendorHash = mkOption {
      type = types.str;
      default = "";
      description = "SHA256 vendor hash for the overridden version.";
      example = "sha256-0HbMMzkxDbDb/Q7s490JfjK63tPdWDuEbV2oQjvD1zI=";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ trivyPackage ];
  };
}
