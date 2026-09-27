## Why

Claude acts as `jan` on Forgejo: forgejo-mcp authenticates with Jan's token and commits carry Jan's git identity. Forgejo does not count an approval from the PR poster, so Jan can never be the second approver next to `ai` on a PR Claude opened (#44).

## What Changes

- `claudeRun` reads `FORGEJO_API_TOKEN` from gopass `home/forgejo/claude-api-token`, the token of the Forgejo user `claude`.
- `claudeRun` gives git the identity `Claude <claude@janbaer.de>` for repos whose remote points at Forgejo. Other repos keep Jan's identity, also inside a Claude session.
- Pushes stay on Jan's SSH key.

## Capabilities

### New Capabilities
- `claude-forgejo-identity`: Claude sessions act as the Forgejo user `claude`, for API calls and for commits in Forgejo repos.

### Modified Capabilities

## Impact

- `modules/home/dev/claude.nix`
- `home/forgejo/api-token` stays: `bin/mirror-forgejo-mcp.sh` in ansible-homelab still pushes the registry image with it.
