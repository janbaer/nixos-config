## 1. Dispatcher

- [x] 1.1 Scan with gitleaks on `pre-commit` and `pre-push` in the dispatcher in `modules/home/dev/git.nix`
- [x] 1.2 Feed the `pre-push` ref lines to the repo-local hook again

## 2. Verify

- [x] 2.1 `nixfmt`, `nix flake check` and build for `jabasoft-pc2`
- [x] 2.2 Scratch repo with the built dispatcher: staged secret blocked, push blocked, secret already on the remote not rescanned, repo-local hook still runs with stdin
- [x] 2.3 Forgejo remote: a `pre-push` scan prints no "Unknown SCM platform"

## 3. Docs

- [x] 3.1 `docs/project.md`
- [x] 3.2 `CHANGELOG.md`
