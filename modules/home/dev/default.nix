{ pkgs, ... }: {
  imports = [
    ./bun.nix
    ./nodejs.nix
    ./git.nix
    ./vscode.nix
    ./golang.nix
    ./python.nix
    ./rust.nix
    ./k8s-cli.nix
    ./claude.nix
    ./zed-editor.nix
    ./devops-tools.nix
    ./goose-cli.nix
    ./mongodb.nix
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    # silent = true; # doesn't work
  };

  home.packages = with pkgs; [
    gcc         # GNU Compiler Collection
    gnumake
    cmake
    jq          # A lightweight and flexible command-line JSON processor
    gojq        # Same as jq, but written in Go and without external dependencies
    jless       # less for Json files or streams
    yq-go       # yaml processor https://github.com/mikefarah/yq
    meld        # Visual diff and merge tool
    lazydocker  # Simple terminal UI for both docker and docker-compose
    devbox      # Reproducible, shareable, and instant development environments
    xh          # Friendly and fast tool for sending HTTP requests (replacement for httpie) - https://github.com/ducaale/xh
  ];

  home.shellAliases = {
    gemini-update = "volta install @google/gemini-cli@latest";
    ld = "DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock lazydocker";
    http = "xh";
  };
}
