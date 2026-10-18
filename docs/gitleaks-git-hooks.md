> **Status:** Draft — 2026-10-17
> **Open:** A real push in a Forgejo repo after the Home Manager switch is not checked yet. Everything was tested with gitleaks 8.30.1 on jabasoft-pc2 only.

# Gitleaks in the git hooks

Every commit and push in every repo is scanned for secrets and blocked on a finding (#47). How gitleaks works, what it detects and what it misses is in the wiki article [Gitleaks](obsidian://open?vault=Obsidian&file=gitleaks), file `DevOPs/Git/gitleaks.md` in the Obsidian vault. This page only describes our integration.

## What runs where

`core.hooksPath` points at a Nix store directory built from `programs.git.hooks` in `modules/home/dev/git.nix`. All four hooks in it are the same dispatcher script. For `pre-commit` and `pre-push` it runs gitleaks first. After a clean scan it hands over to `.githooks/<hook>` of the repo, else to `.git/hooks/<hook>`.

| Hook | Scan | Command |
| --- | --- | --- |
| `pre-commit` | staged changes | `gitleaks git --pre-commit --staged` |
| `pre-push` | per pushed ref, the commits no remote-tracking ref has | `gitleaks git --platform gitea --log-opts="<local sha> --not --remotes"` |

Both calls add `--redact --no-banner --log-level warn -v`. The binary is `pkgs.gitleaks` from the store, not from `PATH`. It is also in `home.packages` for manual runs.

## Behavior

- A finding, or any other non-zero exit of gitleaks, blocks the commit or push. A clean scan prints nothing.
- The dispatcher reads the `pre-push` ref lines from stdin. It feeds them again to the repo-local hook, so tools like pre-commit, husky and lefthook still get them.
- Ref lines with an all-zero local sha (a deletion) are skipped.
- A new branch scans only the commits no remote has. A secret that already reached a remote is not found again, old history is never rescanned.
- `--platform gitea` stops the SSH alias `forgejo` from logging "Unknown SCM platform". It only matters for `pre-push`: a staged scan has no commits and no links.

## False positives and bypass

- A false positive goes into `.gitleaksignore` in the repo root (one fingerprint per line, as printed in the finding), or the line gets a `gitleaks:allow` comment.
- `git commit --no-verify` and `git push --no-verify` skip the hooks. In Lazygit, Ctrl+p pushes with `--no-verify --force-with-lease`.
- There is no other bypass and no environment variable.

## Limits

- The hooks run on the machine only. Nothing checks on the Forgejo server, and there is no CI.
- A host picks the hooks up with its next Home Manager switch.
- The hooks also run in work repos. They only read, they create no commit.
- `pre-push` scans merge commits with `-m` (a diff against each parent), so a secret that exists only in a merge resolution is found. A clean merge that brings in an old secret already on a remote is blocked too. `--no-verify` is the way past it.

## Check it

```bash
tmp=$(mktemp -d); git init -q --bare "$tmp/remote.git"; git clone -q "$tmp/remote.git" "$tmp/work"; cd "$tmp/work"
echo "token = \"ghp_$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)\"" > leak.txt
git add leak.txt && git commit -m leak                     # blocked, exit 1
git commit --no-verify -m leak && git push origin HEAD     # push blocked, exit 1
```

A secret that only exists in a merge commit, with clean parents:

```bash
base=$(git branch --show-current)
git checkout -qb ea; echo 1 > ea.txt; git add ea.txt; git commit -qm ea
git checkout -q "$base"; git checkout -qb eb; echo 2 > eb.txt; git add eb.txt; git commit -qm eb
git checkout -q ea; git merge -q --no-commit --no-ff eb
echo "token = \"ghp_$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)\"" > evil.txt; git add evil.txt
git commit -m merge                                     # blocked by pre-commit, exit 1
git commit --no-verify -m merge && git push origin ea   # push blocked, exit 1
```

The full test steps are in the "How to Test" section of issue #47. The reasons behind the design are in `design.md`.
