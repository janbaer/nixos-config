{pkgs, ...}: {
  imports = [
    ./nodejs.nix
    ./git.nix
    ./vscode.nix
    ./golang.nix
    ./rust.nix
  ];

  home.packages = with pkgs; [
    gcc       # GNU Compiler Collection
    gnumake
    cmake
    jq 		    # A lightweight and flexible command-line JSON processor
    jless           # less for Json files or streams
    yq-go 	    # yaml processor https://github.com/mikefarah/yq
    httpie          # Command line HTTP client whose goal is to make CLI human-friendly.
  ];
}
  programs.direnv = {
    enable = true;
    nix-direnv.enable =
      true;
  };

    devenv          # Fast, Declarative, Reproducible, and Composable Developer Environments.
