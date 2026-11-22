{
  monitors = [ ];

  useHyprland = true;
  useTuxedo = false;

  # Wallpaper directory (relative to $HOME), shared across all hosts
  wallpaperDir = "Pictures/wallpapers";

  # Common GPG configuration
  gpgKey = "EB90F9C1";
  gpgSshKeys = [
    "710619CBFD98D8385CD2DC21C300BA86FEE2C7DE" # Forgejo
    "800DCF4F8B668634FCC7C49D284EA53CD9B6997B" # JABASOFT systems
    "F91C3CAF78F8DF6D544D04EF547AAB92B6CD08ED" # Github
  ];

  # SSH configuration
  # Exported with a trailing "!": without it, gpg returns the most
  # recent auth subkey instead of the one asked for.
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEhmAUerrshNotNG3UfeHU6T15/YhaHdZH9KGD79rrN openpgp:0xE72E7965"
  ];

  # WireGuard configuration
  wgEndpoint = "janbaer.home64.de:1194";
  wgAllowedIPs = [ "0.0.0.0/0" ];
  wgPublicKey = "";
  wgIPAddress = "";

  # Node.js major version installed via mise. Intentionally a floating major
  # ("24" resolves to the latest 24.x) — matches volta's previous behaviour;
  # patch versions are not pinned for dev tooling.
  nodeVersion = "24";

  # Common global NPM packages
  globalNpmPackages = [
    "typescript@latest"                     # TypeScript compiler
    "typescript-language-server@latest"     # LSP for TypeScript (used in Claude)
    "vscode-langservers-extracted@latest"   # VS Code language servers
    "@rivolink/leaf"                        # Terminal Markdown previewer
  ];

  # Common SSH configuration
  sshPort = 22022;

  # Obsidian vault path
  obsidianVault = "";

  # Shell aliases, extended per host
  aliases = { };

  # SSH matchBlocks for host-specific configuration
  sshMatchBlocks = { };

  dictation = {
    sttModel = "mistralai/voxtral-mini-transcribe";
    cleanupModel = "mistralai/mistral-small-2603";

    # Bedeutung und Begründung der Schlüssel: modules/home/desktop/dictate/README.md
    cleanupFallbackModels = [ "google/gemini-2.5-flash" ];
    cleanupProviders = [ "mistral" ];
    holdDelay = "1";
  };
}
