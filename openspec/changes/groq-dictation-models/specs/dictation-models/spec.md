## ADDED Requirements

### Requirement: Configurable dictation models
The dictation pipeline SHALL read its speech-to-text model and cleanup model from `hosts/${hostname}/variables.nix` (via `hosts/common/variables.nix`), so the models used can be changed per host without editing `dictate.nix` or `dictate.sh`.

#### Scenario: Host variables define the active models
- **WHEN** `modules.desktop.dictate` is enabled for a host
- **THEN** the built `dictate` command uses `dictation.sttModel` and `dictation.cleanupModel` from that host's variables as the `DICTATE_SPEECH_MODEL` and `DICTATE_CLEANUP_MODEL` values

### Requirement: Cleanup provider pinning
The cleanup request SHALL be restricted to the providers listed in `dictation.cleanupProviders`, with no silent fallback to an unlisted provider.

#### Scenario: Cleanup provider list is non-empty
- **WHEN** `dictation.cleanupProviders` lists one or more OpenRouter provider slugs
- **THEN** the cleanup request only allows those providers, and a request that cannot be routed to one of them fails rather than routing elsewhere

#### Scenario: Speech-to-text has no provider restriction
- **WHEN** the speech-to-text request is sent
- **THEN** it carries no provider allow-list, because OpenRouter does not support provider-pinning on the transcription endpoint
