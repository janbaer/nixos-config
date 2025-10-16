let
  commonVars = import ./../common/variables.nix;
in
commonVars // {
  # Host-specific overrides
  extraMonitorSettings = ''
    monitor = eDP-1,preferred,auto,1.5
  '';

  # Host-specific WireGuard settings
  wgPublicKey = "xcQlGyurzhQ3NZnL1QWrVivP6yQioSCMnlNYwCoa9k4=";
  wgIPAddress = "192.168.2.6/32";
}
