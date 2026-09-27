## 1. claudeRun

- [x] 1.1 Read `FORGEJO_API_TOKEN` from `home/forgejo/claude-api-token`
- [x] 1.2 Add a store file with Claude's `user.name`/`user.email` and inject the two `includeIf` entries via `GIT_CONFIG_*`

## 2. Verify

- [x] 2.1 `nix flake check` and build for `jabasoft-pc2`
- [x] 2.2 After switch: `get_my_user_info` returns `claude`
- [x] 2.3 Identity checks for Forgejo, GitHub and normal-shell cases
- [ ] 2.4 First PR by `claude` gets an `ai` review and Jan's approval counts

## 3. Docs

- [x] 3.1 Document the `claude` user and token in ansible-homelab `services/forgejo/README.md`
