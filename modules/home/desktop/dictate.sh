#!/usr/bin/env bash
set -euo pipefail

# Push-to-toggle dictation: one keybind starts the recording, the same keybind
# stops it, uploads the WAV to OpenRouter and puts the transcript into the
# focused window. State lives in a pidfile because the two presses are two
# independent process invocations — the second one has no shell context from
# the first.
#
# This file is packaged by dictate.nix via writeShellApplication, which prepends
# its own shebang plus `set -euo pipefail` (the two lines above are duplicates
# for standalone runs and harmless) and pins PATH to runtimeInputs. That
# `set -e` is why nearly every command below carries an explicit `|| true` /
# `|| var=""` — a failing notify-send or curl must not abort a session.
#
# Configuration arrives as DICTATE_* environment variables exported by the Nix
# module. The defaults below only apply when the script is run directly for
# testing (`DICTATE_PASTE_MODE=type bash dictate.sh`); the authoritative values
# are the option defaults in dictate.nix.

DICTATE_SPEECH_MODEL="${DICTATE_SPEECH_MODEL:-openai/whisper-large-v3-turbo}"
DICTATE_CLEANUP_MODEL="${DICTATE_CLEANUP_MODEL:-deepseek/deepseek-v4-flash}"
DICTATE_LANGUAGE="${DICTATE_LANGUAGE:-}"
DICTATE_GOPASS_PATH="${DICTATE_GOPASS_PATH:-cloud/openrouter/stt}"
DICTATE_STOP_DELAY="${DICTATE_STOP_DELAY:-0.8}"
DICTATE_RESTORE_DELAY="${DICTATE_RESTORE_DELAY:-0.5}"
DICTATE_TYPE_DELAY="${DICTATE_TYPE_DELAY:-12}"
DICTATE_PASTE_MODE="${DICTATE_PASTE_MODE:-paste}"
DICTATE_TERMINAL_CLASSES="${DICTATE_TERMINAL_CLASSES:-com.mitchellh.ghostty}"
# Diagnostic switch, deliberately not a Nix option: it exists to split the
# pipeline when the result looks wrong, not to be configured per host.
#
# TEMPORARILY defaulted to 1: the lost-tail bug is intermittent, so it has to be
# recorded while dictating normally via the keybind — an opt-in flag would only
# ever be set when the bug is not happening. Costs a plaintext transcript of
# every dictation in tmpfs. Set back to 0 once the cause is found.
DICTATE_DEBUG="${DICTATE_DEBUG:-1}"
DICTATE_CLEANUP_PROMPT="${DICTATE_CLEANUP_PROMPT:-You are a transcription cleanup tool. The user message is raw speech-to-text output. Fix spelling, punctuation, capitalization and obvious recognition errors. Preserve the original wording, meaning and language exactly — do not translate, summarize, answer or add anything. Output only the corrected text.}"

# XDG_RUNTIME_DIR is tmpfs, per-user and wiped on logout — recordings never
# survive a session and never land on disk.
state="${XDG_RUNTIME_DIR:-/tmp}/dictate"
pidfile="$state.pid"
wavfile="$state.wav"
logfile="$state.log"

clean=0
if [ "${1:-}" = "--clean" ]; then clean=1; fi

# The DICTATION_* names are the ad-hoc override layer: they let a single shell
# try another model without touching the host config or rebuilding.
speech_model="${DICTATION_SPEECH_MODEL:-$DICTATE_SPEECH_MODEL}"
cleanup_model="${DICTATION_CLEANUP_MODEL:-$DICTATE_CLEANUP_MODEL}"

# x-canonical-private-synchronous replaces the previous dictate popup instead of
# stacking a new one for every state change.
notify() { notify-send -a Dictate -h string:x-canonical-private-synchronous:dictate -t "${2:-2500}" "$1" || true; }

# With DICTATE_DEBUG=1 every stage writes its intermediate result to the log, so
# a truncated or mangled result can be pinned on the recording, the speech model
# or the cleanup model instead of being guessed at from the final text.
debug() {
  if [ "$DICTATE_DEBUG" = 1 ]; then
    printf '%s\n' "$1" >> "$logfile" || true
  fi
}

if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  rec_pid="$(cat "$pidfile")"
  # Drop the pidfile before the delay: a stray second press during transcription
  # then starts a fresh recording instead of signalling a pid that is already
  # gone.
  rm -f "$pidfile"
  sleep "$DICTATE_STOP_DELAY"
  # SIGINT, not SIGTERM — sox only writes the final WAV header on a clean
  # shutdown. A killed rec leaves a file the API rejects.
  kill -INT "$rec_pid" 2>/dev/null || true
  # rec is a child of the *first* invocation, so `wait` is unavailable here;
  # tail --pid blocks until that foreign pid exits.
  tail --pid="$rec_pid" -f /dev/null 2>/dev/null || true

  notify "Transcribing…"
  # soxi reads the duration from the WAV header, so this also confirms the
  # header was written properly when rec was stopped.
  debug "=== $(date -Is) speech=$speech_model clean=$clean audio=$(soxi -D "$wavfile" 2>/dev/null || echo '?')s"
  # Key is read per invocation instead of via agenix: dictation is interactive
  # anyway, so the gopass agent is unlocked and the key never has to exist as a
  # file in the Nix store or /run.
  key="$(gopass show -o "$DICTATE_GOPASS_PATH")"
  args=(-sS https://openrouter.ai/api/v1/audio/transcriptions
    -H "Authorization: Bearer $key"
    -F "file=@$wavfile"
    -F "model=$speech_model")
  if [ -n "$DICTATE_LANGUAGE" ]; then
    args+=(-F "language=$DICTATE_LANGUAGE")
  fi
  text="$(curl "${args[@]}" | jq -r '.text // empty')" || text=""
  rm -f "$wavfile"
  debug "raw     : $text"

  if [ -z "$text" ]; then
    notify "Dictate: no transcription"
    exit 0
  fi

  if [ "$clean" = 1 ]; then
    notify "Cleaning up…"
    # Build the request with jq -n --arg rather than string interpolation: both
    # the prompt and the transcript are arbitrary text and would otherwise break
    # the JSON on the first quote or newline.
    # shellcheck disable=SC2016
    body="$(jq -n --arg m "$cleanup_model" --arg sys "$DICTATE_CLEANUP_PROMPT" --arg u "$text" \
      '{model:$m, temperature:0, messages:[{role:"system",content:$sys},{role:"user",content:$u}]}')"
    cleaned="$(curl -sS https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
      -d "$body" | jq -r '.choices[0].message.content // empty')" || cleaned=""
    debug "cleaned : $cleaned"
    if [ -n "$cleaned" ]; then text="$cleaned"; fi
  fi

  if [ "$DICTATE_PASTE_MODE" = "paste" ]; then
    # Borrow the clipboard and hand it back afterwards. Only text is preserved —
    # an image on the clipboard is lost across a dictation.
    previous="$(wl-paste --no-newline 2>/dev/null || true)"
    printf '%s' "$text" | wl-copy --type text/plain

    # Terminals take Ctrl+Shift+V, everything else Ctrl+V, so the paste shortcut
    # depends on the class of the currently focused window.
    class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')" || class=""
    mapfile -t terminals <<< "$DICTATE_TERMINAL_CLASSES"
    shifted=0
    for t in "${terminals[@]}"; do
      if [ -n "$t" ] && [ "$class" = "$t" ]; then shifted=1; fi
    done

    if [ "$shifted" = 1 ]; then
      wtype -M ctrl -M shift -k v -m shift -m ctrl
    else
      wtype -M ctrl -k v -m ctrl
    fi

    sleep "$DICTATE_RESTORE_DELAY"

    # cliphist watches the clipboard, so the transcript ends up in the clipboard
    # history. Drop that entry again — but only if the newest entry really is our
    # text, otherwise we would delete whatever the user copied in the meantime.
    entry="$(cliphist list 2>/dev/null | head -1 || true)"
    if [ -n "$entry" ] && [ "$(printf '%s\n' "$entry" | cliphist decode 2>/dev/null || true)" = "$text" ]; then
      printf '%s\n' "$entry" | cliphist delete
    fi

    if [ -n "$previous" ]; then
      printf '%s' "$previous" | wl-copy --type text/plain
    else
      wl-copy --clear
    fi
  else
    # Leading Shift_L is a throwaway keypress: the compositor needs a moment to
    # pick up wtype's freshly created virtual keyboard and swallows whatever
    # arrives first. Better a lost modifier than a lost first character.
    wtype -d "$DICTATE_TYPE_DELAY" -k Shift_L "$text"
  fi
else
  # Clean up leftovers from a run that died between start and stop.
  rm -f "$pidfile" "$wavfile"
  # Mono 16 kHz is what Whisper resamples to internally — recording anything
  # richer only inflates the upload.
  rec -q -c 1 -r 16000 "$wavfile" &
  echo "$!" > "$pidfile"
  notify "🎙 Recording — press again to stop"
fi
