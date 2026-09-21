#!/usr/bin/env bash
set -euo pipefail

# Push-to-toggle dictation. See README.md for configuration, debugging and the
# reasons behind the details below.
#
# writeShellApplication runs this under set -e, so commands that may fail
# without ending the session carry an explicit `|| true` or `|| var=""`.

DICTATE_GOPASS_PATH="${DICTATE_GOPASS_PATH:-cloud/openrouter/stt}"
DICTATE_STOP_DELAY="${DICTATE_STOP_DELAY:-0.8}"
DICTATE_RESTORE_DELAY="${DICTATE_RESTORE_DELAY:-0.5}"
DICTATE_MAX_SECONDS="${DICTATE_MAX_SECONDS:-600}"
DICTATE_TERMINAL_CLASSES="${DICTATE_TERMINAL_CLASSES:-com.mitchellh.ghostty}"
DICTATE_AUDIO_FORMAT="${DICTATE_AUDIO_FORMAT:-ogg}"
DICTATE_DEBUG="${DICTATE_DEBUG:-0}"
# No defaults for what decides the result, so a missing value fails instead of
# a stale copy being used. Empty lists are valid for the two list variables.
: "${DICTATE_SPEECH_MODEL:?set by dictate.nix}"
: "${DICTATE_CLEANUP_MODEL:?set by dictate.nix}"
: "${DICTATE_CLEANUP_FALLBACK_MODELS?set by dictate.nix}"
: "${DICTATE_CLEANUP_PROVIDERS?set by dictate.nix}"
: "${DICTATE_CLEANUP_PROMPT:?set by dictate.nix}"

state="${XDG_RUNTIME_DIR:-/tmp}/dictate"
pidfile="$state.pid"
lockfile="$state.lock"
logfile="$state.log"
# Named after this invocation's pid, so a stop press can only ever touch the
# recording it started.
recfile="$state.$$.$DICTATE_AUDIO_FORMAT"

notify() { notify-send -a Dictate -h string:x-canonical-private-synchronous:dictate -t "${2:-2500}" "$1" || true; }

debug() {
  if [ "$DICTATE_DEBUG" = 1 ]; then
    printf '%s\n' "$1" >>"$logfile" || true
  fi
}

now() { date +%s%3N; }

# Prints the API error of an OpenRouter response, or nothing if it has none.
api_error() {
  [ -n "$1" ] || { echo "<no response>"; return; }
  jq -r '.error // empty | "\(.code) \(.metadata.raw // .message)"' <<<"$1" 2>/dev/null || printf '%s' "$1"
}

vocabfile="${XDG_CONFIG_HOME:-$HOME/.config}/dictate/vocabulary.txt"
if [ -r "$vocabfile" ]; then
  vocab=""
  # The || catches a last line written without a trailing newline.
  while read -r term || [ -n "$term" ]; do
    case "$term" in '' | '#'*) continue ;; esac
    vocab="${vocab:+$vocab, }$term"
  done <"$vocabfile"
  if [ -n "$vocab" ]; then
    DICTATE_CLEANUP_PROMPT="$DICTATE_CLEANUP_PROMPT More recurring proper nouns; when a word closely resembles one of these, it is that term and should be spelled accordingly: $vocab. Output only the corrected text."
    debug "vocab   : $vocab"
  fi
fi

# Makes the start/stop decision atomic. Released as soon as the pidfile is
# written or removed, never held across a wait.
exec 9>"$lockfile"
flock 9

rec_pid=""
if [ -f "$pidfile" ]; then
  candidate=""
  candidate_file=""
  { read -r candidate || true; read -r candidate_file || true; } <"$pidfile"
  # A stale pid may belong to an unrelated process by now.
  if [ -n "$candidate" ] && [ "$(cat "/proc/$candidate/comm" 2>/dev/null || true)" = rec ]; then
    rec_pid="$candidate"
    recfile="${candidate_file:-$state.$DICTATE_AUDIO_FORMAT}"
  fi
fi

if [ -n "$rec_pid" ]; then
  t_key="$(now)"
  rm -f "$pidfile"
  flock -u 9
  sleep "$DICTATE_STOP_DELAY"
  # SIGINT, not SIGTERM: sox only closes the file properly on a clean shutdown.
  kill -INT "$rec_pid" 2>/dev/null || true
  # rec is a child of the start invocation, so `wait` cannot be used here.
  tail --pid="$rec_pid" -f /dev/null 2>/dev/null || true

  notify "Transcribing…"
  t_stt="$(now)"
  debug "=== $(date -Is) speech=$DICTATE_SPEECH_MODEL clean=$DICTATE_CLEANUP_MODEL fmt=$DICTATE_AUDIO_FORMAT audio=$(soxi -D "$recfile" 2>/dev/null || echo '?')s bytes=$(stat -c%s "$recfile" 2>/dev/null || echo '?')"
  key="$(gopass show -o "$DICTATE_GOPASS_PATH")" || {
    rm -f "$recfile"
    notify "Dictate: could not read API key"
    exit 1
  }
  response="$(curl -sS --max-time 30 https://openrouter.ai/api/v1/audio/transcriptions \
    -H "Authorization: Bearer $key" \
    -F "file=@$recfile" \
    -F "model=$DICTATE_SPEECH_MODEL" 2>&1)" || true
  text="$(jq -r '.text // empty' <<<"$response" 2>/dev/null)" || text=""
  if [ "$DICTATE_DEBUG" = 1 ]; then
    keepfile="$state-$(date +%Y%m%d-%H%M%S).$DICTATE_AUDIO_FORMAT"
    mv -f "$recfile" "$keepfile" 2>/dev/null || rm -f "$recfile"
    debug "audio   : $keepfile"
  else
    rm -f "$recfile"
  fi
  t_cleanup="$(now)"
  debug "raw     : $text"

  if [ -z "$text" ]; then
    error="$(api_error "$response")"
    if [ -n "$error" ]; then
      debug "error   : $error"
      notify "Dictate: transcription failed" 5000
    else
      notify "Dictate: no transcription"
    fi
    exit 0
  fi

  notify "Cleaning up…"
  # An order, not `only`: OpenRouter applies it to every model in `models`, and
  # `only` would make the fallback models unreachable.
  # shellcheck disable=SC2016
  body="$(jq -n --arg m "$DICTATE_CLEANUP_MODEL" --arg fb "$DICTATE_CLEANUP_FALLBACK_MODELS" \
    --arg p "$DICTATE_CLEANUP_PROVIDERS" --arg sys "$DICTATE_CLEANUP_PROMPT" --arg u "$text" \
    'def lines: split("\n") | map(select(length > 0));
     {models:([$m] + ($fb | lines)),
      temperature:0, reasoning:{enabled:false},
      provider:(if ($p | lines) == [] then {sort:"throughput"} else {order:($p | lines)} end),
      messages:[{role:"system",content:$sys},{role:"user",content:$u}]}')"
  response="$(curl -sS --max-time 30 https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
    -d "$body" 2>&1)" || true
  cleaned="$(jq -r '.choices[0].message.content // empty' <<<"$response" 2>/dev/null)" || cleaned=""
  if [ "$DICTATE_DEBUG" = 1 ]; then
    debug "model   : $(jq -r '.model // "?"' <<<"$response" 2>/dev/null || echo '?')"
  fi
  debug "cleaned : $cleaned"
  if [ -z "$cleaned" ]; then
    debug "error   : $(api_error "$response")"
    notify "Dictate: cleanup failed, pasted raw transcript" 5000
  fi
  # A cleanup far off the raw length is the model answering the dictation
  # instead of cleaning it. The raw transcript is pasted then.
  if [ -n "$cleaned" ]; then
    min_ratio=60
    max_ratio=160
    ratio=$((${#cleaned} * 100 / ${#text}))
    if [ "$ratio" -ge "$min_ratio" ] && [ "$ratio" -le "$max_ratio" ]; then
      text="$cleaned"
    else
      debug "rejected: cleanup returned ${ratio}% of the raw length"
    fi
  fi
  t_out="$(now)"

  previous="$(wl-paste --no-newline 2>/dev/null || true)"
  printf '%s' "$text" | wl-copy --type text/plain || true

  class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')" || class=""
  # Comma-separated is accepted too, for ad-hoc overrides from a shell.
  mapfile -t terminals <<<"${DICTATE_TERMINAL_CLASSES//,/$'\n'}"
  shifted=0
  for t in "${terminals[@]}"; do
    if [ -n "$t" ] && [ "$class" = "$t" ]; then shifted=1; fi
  done

  if [ "$shifted" = 1 ]; then
    wtype -M ctrl -M shift -k v -m shift -m ctrl || true
  else
    wtype -M ctrl -k v -m ctrl || true
  fi

  sleep "$DICTATE_RESTORE_DELAY"

  # Remove the transcript from the cliphist history, but only if the newest
  # entry is still our text and not something copied in the meantime.
  entry="$(cliphist list 2>/dev/null | head -1 || true)"
  if [ -n "$entry" ] && [ "$(printf '%s\n' "$entry" | cliphist decode 2>/dev/null || true)" = "$text" ]; then
    printf '%s\n' "$entry" | cliphist delete || true
  fi

  if [ -n "$previous" ]; then
    printf '%s' "$previous" | wl-copy --type text/plain || true
  else
    wl-copy --clear || true
  fi

  t_end="$(now)"
  debug "timing  : stop=$((t_stt - t_key))ms stt=$((t_cleanup - t_stt))ms cleanup=$((t_out - t_cleanup))ms out=$((t_end - t_out))ms total=$((t_end - t_key))ms"
else
  rm -f "$pidfile" "$recfile"
  # 48 kHz and ALSA keep the audio lost at SIGINT shorter than
  # DICTATE_STOP_DELAY; trim caps a forgotten recording. See README.md.
  AUDIODRIVER=alsa rec -q -c 1 -r 48000 "$recfile" trim 0 "$DICTATE_MAX_SECONDS" &
  printf '%s\n%s\n' "$!" "$recfile" >"$pidfile"
  flock -u 9

  # Announce the recording only once PipeWire reports our capture stream as
  # running. Before that, spoken words are lost.
  ready=0
  for _ in $(seq 1 100); do
    # A stop press during the wait removes the pidfile and takes over.
    [ -f "$pidfile" ] || exit 0
    if pw-dump 2>/dev/null | jq -e '.[] | select(.info.props."node.name" == "alsa_capture.sox" and .info.state == "running")' >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 0.03
  done
  if [ "$ready" = 1 ]; then
    notify "🎙 Recording — press again to stop"
  else
    notify "Dictate: recording did not start"
  fi
fi
