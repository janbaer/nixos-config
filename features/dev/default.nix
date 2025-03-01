{pkgs, ...}: {
  imports = [
    ./nodejs.nix
    ./git.nix
    ./vscode.nix
    ./golang.nix
  ];

  home.packages = with pkgs; [
    jq 		# A lightweight and flexible command-line JSON processor
    yq-go 	# yaml processor https://github.com/mikefarah/yq
  ];
}
