let
  commonVars = import ./../common/variables.nix;
in
commonVars
// {
  # Host-specific overrides
  monitors = [
    {
      output = "DP-1";
      mode = "3840x2160@60";
      position = "0x0";
      scale = "auto";
    }
    # scale: numeric per docs; "auto" above is the keyword form. Mixing the two
    # is accepted by hl.monitor (verified on 0.55.2) — the handler coerces both.
    {
      output = "HDMI-A-1";
      mode = "2560x1600@60";
      position = "500x2160";
      scale = 1;
    }
  ];

  aliases = {
    trivy = "nix develop path:$HOME/Projects/nixos-config/dev-shells/trivy --command trivy";
  };

  # Optional SSH host blocks, merged into programs.ssh.settings. Upstream
  # directive names; the attribute name is the host pattern.
  sshMatchBlocks = {
    "gitlab.com" = {
      User = "jan.baer-check24";
    };
    "*.intern.bu.check24.de" = {
      Port = 44022;
      IdentityFile = "~/.ssh/id_ed25519-sk";
      IdentitiesOnly = true;
      User = "jan.baer";
      ControlMaster = "auto";
      ControlPath = "~/.ssh/control-%h_%p_%r";
      ControlPersist = "30m";
    };
  };
}
