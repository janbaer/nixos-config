# gitleaks-git-hooks Specification

## Purpose
TBD - created by archiving change gitleaks-git-hooks. Update Purpose after archive.
## Requirements
### Requirement: Secrets blocked at commit
The git hook dispatcher SHALL scan the staged changes with gitleaks on `pre-commit` and block the commit on a finding.

#### Scenario: Staged secret
- **WHEN** a commit stages a file with a secret
- **THEN** the commit fails with a non-zero exit code
- **AND** the output names the file and rule but not the secret

#### Scenario: Clean commit
- **WHEN** a commit stages no secret
- **THEN** the commit succeeds and gitleaks prints nothing

### Requirement: Secrets blocked at push
The git hook dispatcher SHALL scan, on `pre-push`, the commits of each pushed ref that no remote-tracking ref contains, and block the push on a finding.

#### Scenario: Secret in an unpushed commit
- **WHEN** a push contains a commit with a secret that no remote has
- **THEN** the push fails with a non-zero exit code

#### Scenario: Secret already on the remote
- **WHEN** a secret was pushed earlier with `--no-verify` and a later push adds only clean commits
- **THEN** the later push succeeds

#### Scenario: Deleting a ref
- **WHEN** a push only deletes a remote branch
- **THEN** nothing is scanned and the push is not blocked

#### Scenario: Secret only in a merge commit
- **WHEN** a merge commit made with `--no-verify` introduces a secret that neither parent has
- **THEN** the push fails with a non-zero exit code
- **AND** a clean merge that brings in a secret already on a remote also fails the push

### Requirement: Repo-local hooks keep working
After a clean scan the dispatcher SHALL hand over to the repo-local `.githooks/<hook>` or `.git/hooks/<hook>` as before, and a `pre-push` hook SHALL still receive the ref lines on stdin.

#### Scenario: Repo-local pre-push hook
- **WHEN** a repo has an executable `.githooks/pre-push` and a clean push runs
- **THEN** the hook runs and reads the same ref lines git sent

### Requirement: Forgejo remotes without warning
`pre-push` SHALL pass `--platform gitea` to gitleaks.

#### Scenario: Forgejo remote
- **WHEN** a push in a repo with remote `git@forgejo:jan/x.git` is scanned
- **THEN** gitleaks prints no "Unknown SCM platform" message

