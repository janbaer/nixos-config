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
    "185800AE5C69C4D90EBAD7A16E2848BE8865994B" # Gitlab (CHECK24)
    "B801FEE5AFB465849C3FDFD59D81D2AA8FA4E625" # Bitbucket (CHECK24)
  ];

  # SSH configuration
  authorizedKeys = [ ];

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
    "typescript@latest"
    "prettier@latest"
    "eslint@9.39.2"
    "yarn@1.22.22"
    "vscode-langservers-extracted@latest"
    "@fission-ai/openspec@latest"
    "gitnexus"
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

    # Anbieter, die das Cleanup ausführen dürfen, als OpenRouter-Slugs. Ein
    # europäisches Modell zu wählen genügt nicht: mistral-small-2603 wird von
    # Mistral und von Venice angeboten, und ohne diese Einschränkung ging bei
    # einem Test einer von drei Aufrufen an Venice. voxtral-mini-transcribe hat
    # als einziger Anbieter Mistral, deshalb war die Spracherkennung nie betroffen.
    #
    # Leere Liste bedeutet: OpenRouter wählt frei, sortiert nach Durchsatz. Das
    # ist die Einstellung für ein Modell ohne Herkunftsanspruch, etwa beim
    # Zurückwechseln auf google/gemini-3.1-flash-lite.
    cleanupProviders = [ "mistral" ];
  };
}
