let
  commonVars = import ./../common/variables.nix;
in
commonVars // {
  # Host-specific overrides
  extraMonitorSettings = ''
    monitor = DP-1, 3840x2160@60, 0x0, auto
    monitor = HDMI-A-1, 1980x1080@60, 3840x240, 1, transform, 3
  '';

  # Optional SSH matchBlocks for host-specific configuration
  sshMatchBlocks = {
    "gitlab.com" = {
      user = "jan.baer-check24";
    };
    "check24-internal" = {
      host = "*.intern.bu.check24.de";
      port = 44022;
      identityFile = "~/.ssh/id_ed25519-sk";
      identitiesOnly = true;
      user = "jan.baer";
      extraOptions = {
        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%h_%p_%r";
        ControlPersist = "30m";
      };
    };
  };
}
