## Context

This change swaps three configured values in the existing dictation pipeline (`modules/home/desktop/dictate.nix` / `dictate.sh`), which already supports per-host STT and cleanup models plus a provider allow-list for cleanup. No new mechanism is needed — the existing options already do what this change requires.

Preceded by a scoping discussion on Forgejo issue #36 that considered and explicitly rejected a larger design: automated LLM-judge quality scoring, running both STT models on every recording to diff them, and calling Groq's API directly (which would need a new credential and script changes). All of that was dropped in favor of the smallest change that lets Jan judge the result by using it.

## Goals / Non-Goals

**Goals:**
- Switch `sttModel` and `cleanupModel` to Groq-hosted models, and pin `cleanupProviders` to Groq only.
- Keep everything else — URLs, gopass key, script logic — exactly as is.

**Non-Goals:**
- No provider pin for speech-to-text (OpenRouter does not support it on the transcription endpoint; confirmed via OpenRouter's docs during the issue's scoping discussion).
- No new credentials, no direct Groq API calls.
- No automated quality/latency measurement beyond the `DICTATE_DEBUG=1` logging that already exists.

## Decisions

- **`sttModel = "openai/whisper-large-v3-turbo"`, unpinned**: the only Groq STT option reachable through OpenRouter without a new credential. Accepted trade-off: OpenRouter may route this to a different host (e.g. DeepInfra) rather than Groq, so this does not guarantee Groq is actually used for STT — Jan accepted that explicitly rather than add a direct-Groq call.
- **`cleanupModel = "openai/gpt-oss-20b"`, `cleanupProviders = ["Groq"]`**: unlike transcription, OpenRouter's chat completions endpoint does support provider pinning, and Groq confirmed hosts this model — so this half of the change does guarantee Groq.
- **No fallback provider in `cleanupProviders`**: matches the existing single-provider pattern (today: `["mistral"]`) — a request that can't reach Groq should fail visibly, not silently reroute elsewhere.

## Risks / Trade-offs

- [Cleanup quality may regress — `gpt-oss-20b` is untested against this cleanup prompt, particularly for German dictations and the existing proper-noun list] → Mitigation: none automated; Jan judges by using it, per the issue's "How to Test." Revert is a one-line variables.nix change.
- [STT may not actually run on Groq, since OpenRouter doesn't guarantee provider for transcription] → Accepted; out of scope to fix here (would need a direct Groq API call).
