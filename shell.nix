let
  # Configure Nix to allow unfree packages.
  config = { allowUnfree = true; };
  pkgs = import <nixpkgs> { inherit config; };
in pkgs.mkShell {
  buildInputs = with pkgs; [
    nh              # We need the nix-helper
    nvd             # Nix/NixOS package version diff tool``
    nixfmt-classic  # Nix code formatter
  ];

  # Automatically run jupyter when entering the shell.
  shellHook = ''
    cat > .zshrc.local << 'EOF'
      # Define aliases
      alias nhs='nh os switch .'
      alias nhb='nh os build .'
    EOF
  '';
}
