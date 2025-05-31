{ pkgs, ... }: {
  imports = [
    ./nodejs.nix
    ./git.nix
    ./vscode.nix
    ./golang.nix
    ./rust.nix
    ./k8s-cli.nix
    ./claude.nix
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    # silent = true; # doesn't work
  };

  home.packages = with pkgs; [
    gcc # GNU Compiler Collection
    gnumake
    cmake
    jq          # A lightweight and flexible command-line JSON processor
    gojq        # Same as jq, but written in Go and without external dependencies
    jless       # less for Json files or streams
    yq-go       # yaml processor https://github.com/mikefarah/yq
    httpie      # Command line HTTP client whose goal is to make CLI human-friendly.
    meld        # Visual diff and merge tool
    zed-editor  # High-performance, multiplayer code editor from the creators of Atom and Tree-sitter
  ];
}
