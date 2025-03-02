{pkgs, ...}: {
  imports = [
    ./nodejs.nix
    ./git.nix
    ./vscode.nix
    ./golang.nix
  ];

  home.packages = with pkgs; [
    gcc       # GNU Compiler Collection
    jq 		    # A lightweight and flexible command-line JSON processor
    yq-go 	  # yaml processor https://github.com/mikefarah/yq
    httpie    # Command line HTTP client whose goal is to make CLI human-friendly.
  ];
}
