{pkgs, ...}: {
  imports = [
    ./dev/nodejs.nix
    ./dev/git.nix
    ./dev/vscode.nix
    ./dev/golang.nix
  ];

  home.packages = with pkgs; [
    jq 		# A lightweight and flexible command-line JSON processor
    yq-go 	# yaml processor https://github.com/mikefarah/yq
  ];
}
