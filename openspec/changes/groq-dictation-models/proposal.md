## Why

Groq advertises very fast inference (up to 1000 tok/s for chat, up to 216x real-time for Whisper transcription). The current dictation pipeline (Voxtral for speech-to-text, Mistral Small for cleanup, both via OpenRouter) works, but Jan wants to test whether switching to Groq-hosted models noticeably cuts the wait between finishing speaking and the cleaned-up text landing in the focused window. Forgejo issue #36.

## What Changes

- `sttModel` changes from `mistralai/voxtral-mini-transcribe` to `openai/whisper-large-v3-turbo`, still called via OpenRouter with no provider pin (OpenRouter does not support provider-pinning on the transcription endpoint, so this matches the existing unpinned pattern).
- `cleanupModel` changes from `mistralai/mistral-small-2603` to `openai/gpt-oss-20b`.
- `cleanupProviders` changes from `["mistral"]` to `["Groq"]` — same pinning mechanism as today, just pointed at a different provider, no fallback.

No script changes, no new credentials, no new Nix options, no new logging or scoring.

## Capabilities

### New Capabilities

- `dictation-models`: this is the first OpenSpec-tracked touch of the dictation pipeline, so this change also formalizes its existing baseline requirement (STT and cleanup models are configured per host, cleanup is pinned to a single allow-listed provider with no silent fallback) rather than leaving it undocumented. The requirement itself does not change — only the configured values do.

### Modified Capabilities

(none)

## Impact

- `hosts/common/variables.nix` — the three values above.
- No other hosts, modules, or scripts are touched. `modules/home/desktop/dictate.nix` and `dictate.sh` read these values as before.
