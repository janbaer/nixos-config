# Dev Shells

Reusable development environments. Enter any of them from any project directory:

```bash
nix develop path:$HOME/Projects/nixos-config/dev-shells/go
nix develop path:$HOME/Projects/nixos-config/dev-shells/rust
nix develop path:$HOME/Projects/nixos-config/dev-shells/devops
nix develop path:$HOME/Projects/nixos-config/dev-shells/claude-desktop
nix develop path:$HOME/Projects/nixos-config/dev-shells/zed-editor
nix develop path:$HOME/Projects/nixos-config/dev-shells/antigravity
nix develop path:$HOME/Projects/nixos-config/dev-shells/trivy
```

To use one with direnv, add this to a project's `.envrc`:

```bash
use flake path:$HOME/Projects/nixos-config/dev-shells/go
```
