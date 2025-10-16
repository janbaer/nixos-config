{
  extraMonitorSettings = ''
  '';

  useHyprland = true;
  useTuxedo = false;

  # Common GPG configuration
  gpgKey = "EB90F9C1";
  gpgSshKeys = [
    "710619CBFD98D8385CD2DC21C300BA86FEE2C7DE" # Forgejo
    "800DCF4F8B668634FCC7C49D284EA53CD9B6997B" # JABASOFT systems
    "F91C3CAF78F8DF6D544D04EF547AAB92B6CD08ED" # Github
    "185800AE5C69C4D90EBAD7A16E2848BE8865994B" # Gitlab (CHECK24)
    "B801FEE5AFB465849C3FDFD59D81D2AA8FA4E625" # Bitbucket (CHECK24)
  ];

  # SSH configuration
  authorizedKeys = [];

  # WireGuard configuration
  wgEndpoint = "janbaer.home64.de:1194";
  wgAllowedIPs = ["0.0.0.0/0"];
  wgPublicKey = "";
  wgIPAddress = "";

  # Common global NPM packages
  globalNpmPackages = [
    "typescript@5.8.3"
    "prettier@3.5.3"
    "eslint@9.28.0"
    "yarn@1.22.22"
    "@google/gemini-cli@latest"
    "@anthropic-ai/claude-code@latest"
  ];

  # Common SSH configuration
  sshPort = 23;

  # SSH matchBlocks for host-specific configuration
  sshMatchBlocks = {};
}
