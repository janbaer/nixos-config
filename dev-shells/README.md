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

## Bumping a pinned version

Only `trivy` pins a version together with its `hash` and `vendorHash`. Change the version and both hashes together.

### Why the version alone is not enough

`fetchFromGitHub` is a fixed-output derivation. Its store path comes from the hash and the name, not from the tag or the URL. The default name is `source`, so with an unchanged hash the path stays the same. Nix finds it in the store, treats the source as satisfied, and never fetches the new tag. The Go build still recompiles, because the derivation name changed, and the `ldflags` stamp the new version into the binary:

```bash
$ trivy --version
Version: 0.74.0                              # the label
$ head -3 /nix/store/933ij…-source/CHANGELOG.md
## [0.70.0] … (2026-04-16)                   # the actual code
```

The build breaks only on a machine that lacks that store path, or after a garbage collect.

The `trivy` flake guards against this by putting the version into the source name:

```nix
src = old.src.override {
  tag = "v${version}";
  name = "trivy-${version}-source";
  inherit hash;
};
```

The path then follows the version (`trivy-0.73.0-source` instead of `source`), so a bump always misses the store, always fetches, and a stale hash fails loudly. Copy that line into any new shell that pins a source.

### Procedure

1. Check that the tag exists. A missing tag gives a 404, not a hash mismatch.
2. Get the source hash with `nurl`:
   ```bash
   nix run nixpkgs#nurl -- https://github.com/aquasecurity/trivy v0.73.0
   ```
   It prints the complete `fetchFromGitHub` block. Without `nurl`:
   ```bash
   nix-prefetch-url --unpack https://github.com/aquasecurity/trivy/archive/refs/tags/v0.73.0.tar.gz
   nix hash convert --hash-algo sha256 --to sri <output>
   ```
3. Set `vendorHash = nixpkgs.lib.fakeHash;`, then build. Copy the `got:` value out of the error.
4. Verify that the store really holds the new source:
   ```bash
   nix eval --impure --raw --expr '(builtins.head (builtins.getFlake (toString ./.)).devShells.x86_64-linux.default.buildInputs).src.outPath'
   ```
   Read the `CHANGELOG.md` in that path.

### Reading the error

Two failures look similar in the build log:

| Log line | Meaning | Gives you a hash? |
| --- | --- | --- |
| `specified: … / got: sha256-…` | hash mismatch | yes, use the `got:` value |
| `curl: (22) … error: 404`, `cannot download source from any mirror` | tag or URL is wrong | no, nothing was downloaded |

Nix reports a `got:` hash only after it downloads and hashes the content. A 404 means there is nothing to hash.
