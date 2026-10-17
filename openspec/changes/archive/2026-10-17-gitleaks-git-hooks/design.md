## Context

`core.hooksPath` points at a Nix store directory built from `programs.git.hooks` in `modules/home/dev/git.nix`. Its dispatcher script runs for `pre-commit`, `commit-msg`, `pre-push` and `post-commit` in every repo, and hands over to `.githooks/<hook>` or `.git/hooks/<hook>`. Remotes are mostly SSH through the alias `forgejo`, so gitleaks sees the host `forgejo` and cannot pick a platform.

## Goals / Non-Goals

**Goals:**
- Every repo is scanned, with no per-repo setup.
- A finding blocks the commit or push.

**Non-Goals:**
- Server-side enforcement on Forgejo.
- A safety net for `--no-verify`. Using it is a deliberate act.
- A baseline for old history: only new commits are scanned.

## Decisions

**Scan in the dispatcher.** The binary is `${pkgs.gitleaks}` from the store, so the hook never depends on `PATH`. The dispatcher and the package come from the same module tree.

**Staged scan on `pre-commit`.** `gitleaks git --pre-commit --staged` reads the staged diff, so it also works for the first commit of a repo.

**Range on `pre-push` from stdin.** For each ref line git sends, the scan covers `<local sha> --not --remotes`: the commits that no remote-tracking ref has. This avoids `@{u}..HEAD`, which fails on new branches, and a range built from `$1`, which breaks when `$1` is a URL. Ref lines with an all-zero local sha (a deletion) are skipped.

**Hand `pre-push` stdin on.** The dispatcher reads the ref lines itself, so it feeds them again to the repo-local hook. Hooks of pre-commit, husky or lefthook read them.

**Quiet on success.** `--no-banner --log-level warn` leaves a clean scan silent. `-v` prints the finding and `--redact` hides the secret.

**`--platform gitea` on `pre-push` only.** The `pre-commit` scan has no commits, so it never prints the warning. `gitea` produces `/src/commit/<sha>/<file>` links, which Forgejo serves.

**No extra bypass.** `git commit --no-verify` and `git push --no-verify` stay as they are. A false positive goes into the repo's `.gitleaksignore` or gets a `gitleaks:allow` comment.

## Risks / Trade-offs

- A broken gitleaks run (any non-zero exit) also blocks.
- The lazygit key for `git push --no-verify --force-with-lease` in `git.nix` skips the push scan by design.
- A local branch that is never pushed is never scanned at push time. `pre-commit` still covers its commits.
