## Context

`claudeRun` (`modules/home/dev/claude.nix`) exports the MCP secrets from gopass and starts `claude`. Git identity comes from `modules/home/dev/git.nix` (`Jan Baer <jan@janbaer.de>`). Forgejo remotes are SSH through the alias `forgejo`, in two spellings: `git@forgejo:jan/x.git` and `ssh://git@forgejo/jan/x.git`.

## Goals / Non-Goals

**Goals:**
- PRs, issues, comments and merges through forgejo-mcp run as `claude`.
- Commits made in a Claude session in a Forgejo repo are authored and committed by `Claude <claude@janbaer.de>`.

**Non-Goals:**
- A separate SSH key for Claude. Forgejo does not care who pushes.
- Required approvals in branch protection, merging by Claude, deployment (separate issue).
- `openRouterClaude`: it exports no Forgejo token today.

## Decisions

**Identity by remote, not by `GIT_AUTHOR_*`.** Exporting `GIT_AUTHOR_*`/`GIT_COMMITTER_*` would also rewrite commits Claude makes in GitHub repos, which must stay Jan's. Instead `claudeRun` injects two `includeIf "hasconfig:remote.*.url:…"` entries through `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n`/`GIT_CONFIG_VALUE_n`, pointing at a store file with `user.name`/`user.email`. Patterns: `git@forgejo:*/**` and `ssh://git@forgejo/**`. Outside `claudeRun` nothing changes.

**Old token stays.** `home/forgejo/api-token` is still used by `bin/mirror-forgejo-mcp.sh` in ansible-homelab.

## Risks / Trade-offs

- A Forgejo remote in another spelling (HTTPS, host `forgejo.home.janbaer.de`) falls back to Jan's identity. No local repo uses one today.
- `GIT_CONFIG_COUNT` set by the caller would be overwritten. Nothing sets it today.
- A `! git commit` inside a Claude session is attributed to Claude.
