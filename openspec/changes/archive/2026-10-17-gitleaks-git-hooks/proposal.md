## Why

A secret that reaches a remote counts as leaked and must be rotated, even if the commit is removed later. Nothing checks commits or pushes today, and adding gitleaks repo by repo would leave gaps (#47).

## What Changes

- The git hook dispatcher runs gitleaks before it hands over to a repo-local hook. `pre-commit` scans the staged changes, `pre-push` scans the commits that no remote has yet.
- A finding blocks the commit or push. The output is redacted and a clean scan prints nothing.
- `pre-push` passes `--platform gitea`, so the `forgejo` SSH alias no longer triggers "Unknown SCM platform".
- `docs/project.md` and `CHANGELOG.md` describe the hooks.

## Capabilities

### New Capabilities
- `gitleaks-git-hooks`: Commits and pushes in every repo are scanned for secrets and blocked on a finding.

### Modified Capabilities

## Impact

- `modules/home/dev/git.nix`
- `modules/home/dev/default.nix`: `gitleaks` in `home.packages` for manual runs, already staged before this change.
- `docs/project.md`, `CHANGELOG.md`
