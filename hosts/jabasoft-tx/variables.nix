let
  commonVars = import ./../common/variables.nix;
in
commonVars
// {
  # Host-specific overrides
  monitors = [
    {
      output = "eDP-1";
      mode = "preferred";
      position = "auto";
      scale = 1.5;
    }
  ];

  useTuxedo = true;

  # Host-specific WireGuard settings
  wgPublicKey = "xcQlGyurzhQ3NZnL1QWrVivP6yQioSCMnlNYwCoa9k4=";
  wgIPAddress = "192.168.2.6/32";
}
