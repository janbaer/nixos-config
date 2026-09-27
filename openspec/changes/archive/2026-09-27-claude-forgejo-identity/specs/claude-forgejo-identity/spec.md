## ADDED Requirements

### Requirement: Forgejo API as claude
`claudeRun` SHALL authenticate forgejo-mcp with the token of the Forgejo user `claude`.

#### Scenario: MCP user
- **WHEN** a session started with `claudeRun` calls `get_my_user_info`
- **THEN** the login is `claude`

### Requirement: Claude identity in Forgejo repos
Inside `claudeRun`, git SHALL use `Claude <claude@janbaer.de>` as author and committer in repos with a Forgejo remote, and Jan's identity everywhere else.

#### Scenario: Forgejo repo in a Claude session
- **WHEN** a commit is made in a repo with remote `git@forgejo:jan/x.git` or `ssh://git@forgejo/jan/x.git` under `claudeRun`
- **THEN** author and committer are `Claude <claude@janbaer.de>`

#### Scenario: Other repo in a Claude session
- **WHEN** a commit is made in a repo with a GitHub remote under `claudeRun`
- **THEN** author and committer are `Jan Baer <jan@janbaer.de>`

#### Scenario: Outside a Claude session
- **WHEN** a commit is made in a Forgejo repo from a normal shell
- **THEN** author and committer are `Jan Baer <jan@janbaer.de>`
