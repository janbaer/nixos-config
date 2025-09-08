{
  useHyprland = true;
  useTuxedo = true;
  extraMonitorSettings = ''
    monitor = eDP-1,preferred,auto,1.5
  '';
  gpgKey = "EB90F9C1";
  gpgSshKeys = [
    "710619CBFD98D8385CD2DC21C300BA86FEE2C7DE" # Forgejo
    "800DCF4F8B668634FCC7C49D284EA53CD9B6997B" # JABASOFT systems
    "F91C3CAF78F8DF6D544D04EF547AAB92B6CD08ED" # Github
    "185800AE5C69C4D90EBAD7A16E2848BE8865994B" # Gitlab (CHECK24)
    "B801FEE5AFB465849C3FDFD59D81D2AA8FA4E625" # Bitbucket (CHECK24)
  ];

  wgEndpoint = "janbaer.home64.de:1194";
  wgPublicKey = "xcQlGyurzhQ3NZnL1QWrVivP6yQioSCMnlNYwCoa9k4=";
  wgIPAddress = "192.168.2.6/32";
  wgAllowedIPs = ["0.0.0.0/0"];

  globalNpmPackages = [
    "typescript@5.8.3"
    "prettier@3.5.3"
    "eslint@9.28.0"
    "yarn@1.22.22"
    "@google/gemini-cli@latest"
    "@anthropic-ai/claude-code@latest"
  ];

  # Optional SSH matchBlocks for host-specific configuration
  sshMatchBlocks = {};
}
