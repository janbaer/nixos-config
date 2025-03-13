let
  # Configure Nix to allow unfree packages.
  config = {
    allowUnfree = true;
  };
  pkgs = import <nixpkgs> { inherit config; };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    nh # We need the nix-helper
    nixfmt
  ];


  # Automatically run jupyter when entering the shell.
  shellHook = ''
    cat > .zshrc.local << 'EOF'
      # Define aliases
      alias nhs='nh os switch .'
    EOF
  '';
}
