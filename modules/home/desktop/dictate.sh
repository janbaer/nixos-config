#!/usr/bin/env bash
set -euo pipefail

# Push-to-toggle dictation: one keybind starts the recording, the same keybind
# stops it, uploads the recording to OpenRouter and puts the transcript into the
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
# testing (`DICTATE_STOP_DELAY=2 bash dictate.sh`); the authoritative values
# are the option defaults in dictate.nix.

DICTATE_SPEECH_MODEL="${DICTATE_SPEECH_MODEL:-mistralai/voxtral-mini-transcribe}"
DICTATE_CLEANUP_MODEL="${DICTATE_CLEANUP_MODEL:-mistralai/mistral-small-2603}"
DICTATE_CLEANUP_PROVIDERS="${DICTATE_CLEANUP_PROVIDERS:-mistral}"
DICTATE_GOPASS_PATH="${DICTATE_GOPASS_PATH:-cloud/openrouter/stt}"
DICTATE_STOP_DELAY="${DICTATE_STOP_DELAY:-0.8}"
DICTATE_RESTORE_DELAY="${DICTATE_RESTORE_DELAY:-0.5}"
DICTATE_TERMINAL_CLASSES="${DICTATE_TERMINAL_CLASSES:-com.mitchellh.ghostty}"
# Container for the recording, chosen by file extension. Ogg Vorbis instead of
# WAV because the upload scales with the dictation length and dominates the wait
# on a home uplink: 8s of German speech is 258 KB as 16 kHz WAV and 42 KB as
# ogg, and Voxtral returned a byte-identical transcript for both. rec encodes
# while recording, so the compression is paid during the dictation, not at stop.
#
# nixpkgs' sox cannot write mp3 (no encoder compiled in) or opus, so the
# alternatives here are only wav and flac (lossless, ~1.9x). Overriding this
# needs both invocations to agree — the start writes the file, the stop reads it
# — so set it in the session environment, not for a single shell.
DICTATE_AUDIO_FORMAT="${DICTATE_AUDIO_FORMAT:-ogg}"
# Diagnostic switch, deliberately not a Nix option: it exists to split the
# pipeline when the result looks wrong, not to be configured per host.
#
# TEMPORARILY defaulted to 1: the lost-tail bug is intermittent, so it has to be
# recorded while dictating normally via the keybind — an opt-in flag would only
# ever be set when the bug is not happening. Costs a plaintext transcript of
# every dictation in tmpfs. Set back to 0 once the cause is found.
DICTATE_DEBUG="${DICTATE_DEBUG:-1}"
DICTATE_CLEANUP_PROMPT="${DICTATE_CLEANUP_PROMPT:-You are a transcription cleanup tool. The user message is raw speech-to-text output. Fix spelling, punctuation, capitalization and obvious recognition errors. Recurring proper nouns: Claude, Claude Code, NixOS, Hyprland, Home Manager, agenix, OpenRouter, Forgejo, Obsidian, Vikunja, Proxmox, Ansible, WireGuard, DynDNS, UniFi, Voxtral, Mistral. When a word closely resembles one of these, it is that term and should be spelled accordingly. The speaker talks about the AI assistant Claude constantly; a transcribed 'Cloud' or 'cloud' is almost always 'Claude' and should only stay 'Cloud' when the sentence is clearly about cloud computing or a cloud provider. Preserve the original wording, meaning and language exactly — do not translate, summarize, answer or add anything. Output only the corrected text.}"

# XDG_RUNTIME_DIR is tmpfs, per-user and wiped on logout — recordings never
# survive a session and never land on disk.
state="${XDG_RUNTIME_DIR:-/tmp}/dictate"
pidfile="$state.pid"
recfile="$state.$DICTATE_AUDIO_FORMAT"
logfile="$state.log"

# x-canonical-private-synchronous replaces the previous dictate popup instead of
# stacking a new one for every state change.
notify() { notify-send -a Dictate -h string:x-canonical-private-synchronous:dictate -t "${2:-2500}" "$1" || true; }

# With DICTATE_DEBUG=1 every stage writes its intermediate result to the log, so
# a truncated or mangled result can be pinned on the recording, the speech model
# or the cleanup model instead of being guessed at from the final text.
debug() {
  if [ "$DICTATE_DEBUG" = 1 ]; then
    printf '%s\n' "$1" >>"$logfile" || true
  fi
}

now() { date +%s%3N; }

if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  # Timestamps are taken unconditionally and only logged under DICTATE_DEBUG.
  # The wait after the stop key is the sum of four terms that scale differently,
  # and the total alone cannot say which one to optimise.
  t_key="$(now)"
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
  t_stt="$(now)"
  # Both model names go into the log. Which speech model ran was always
  # answerable from it; which cleanup model ran had to be argued from the shape
  # of its output, which is a bad position to be in when the question is what
  # produced a wrong transcript.
  # soxi reads the duration back out of the finished file, so this also confirms
  # the container was closed properly when rec was stopped.
  debug "=== $(date -Is) speech=$DICTATE_SPEECH_MODEL clean=$DICTATE_CLEANUP_MODEL fmt=$DICTATE_AUDIO_FORMAT audio=$(soxi -D "$recfile" 2>/dev/null || echo '?')s bytes=$(stat -c%s "$recfile" 2>/dev/null || echo '?')"
  # Key is read per invocation instead of via agenix: dictation is interactive
  # anyway, so the gopass agent is unlocked and the key never has to exist as a
  # file in the Nix store or /run.
  key="$(gopass show -o "$DICTATE_GOPASS_PATH")"
  # No language parameter: the model detects it per recording, and German and
  # English dictations come back equally well without one.
  text="$(curl -sS https://openrouter.ai/api/v1/audio/transcriptions \
    -H "Authorization: Bearer $key" \
    -F "file=@$recfile" \
    -F "model=$DICTATE_SPEECH_MODEL" | jq -r '.text // empty')" || text=""
  # Under debug the recording is kept instead of deleted. Without it a report of
  # "the first word is missing" cannot be answered: the transcript alone cannot
  # say whether the word was never captured or was captured and not transcribed,
  # and by the time the question comes up the evidence is gone. Same mistake as
  # the empty transcription earlier, where the API response was discarded too.
  # Stays in tmpfs, so it disappears at logout, and goes away with the debug
  # switch.
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
    notify "Dictate: no transcription"
    exit 0
  fi

  notify "Cleaning up…"
  # Build the request with jq -n --arg rather than string interpolation: both
  # the prompt and the transcript are arbitrary text and would otherwise break
  # the JSON on the first quote or newline.
  # Two independent causes made the cleanup wait feel random, and both had to
  # go before either was visible. Both were measured on the previous default,
  # deepseek/deepseek-v4-flash; the settings stay because they cost nothing on
  # a model that does not need them and matter again on any model that does.
  #
  # reasoning: the model thinks before answering by default and burned 284 of
  # 330 completion tokens on reasoning for a punctuation fix. Thinking length
  # is unrelated to input length, which is why comparable dictations took
  # anywhere from 1.0s to 13.2s. Turning it off costs a little accuracy on
  # unusual words ("publischen" became "publizieren" with reasoning, but
  # "publishen" without); the corrections that matter — proper nouns,
  # sentence boundaries, dropped negations — survive.
  #
  # Provider routing. Choosing a European model says nothing about who runs it:
  # OpenRouter is a router, and mistral-small-2603 is offered by Mistral and by
  # Venice alike, so without a restriction the transcript can land at either.
  # An allow-list is enforced rather than preferred — an unknown slug fails with
  # "No allowed providers are available" instead of quietly routing elsewhere.
  #
  # An empty list means no origin requirement, and then sorting matters again:
  # with the reasoning noise gone, the remaining spread was purely which
  # provider OpenRouter load-balanced onto, and identical 120-token requests
  # took 2.5s on Alibaba against 36.6s on Io Net. Throughput and not latency,
  # because this is a fixed-size rewrite where the whole output is needed —
  # time to last token, not time to first.
  if [ -n "$DICTATE_CLEANUP_PROVIDERS" ]; then
    provider="$(jq -n --arg p "$DICTATE_CLEANUP_PROVIDERS" \
      '{only: ($p | split("\n") | map(select(length > 0)))}')"
  else
    provider='{"sort":"throughput"}'
  fi
  # shellcheck disable=SC2016
  body="$(jq -n --arg m "$DICTATE_CLEANUP_MODEL" --arg sys "$DICTATE_CLEANUP_PROMPT" --arg u "$text" --argjson prov "$provider" \
    '{model:$m, temperature:0, reasoning:{enabled:false}, provider:$prov,
      messages:[{role:"system",content:$sys},{role:"user",content:$u}]}')"
  cleaned="$(curl -sS https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
    -d "$body" | jq -r '.choices[0].message.content // empty')" || cleaned=""
  debug "cleaned : $cleaned"
  # The cleanup model breaks role on roughly a fifth of the dictations that
  # end in a question aimed at an assistant: it answers the question instead
  # of cleaning the text, in one observed case with a canned Chinese "I have
  # no information on that". It happens with reasoning on and off alike, and
  # rewording the prompt did not measurably help, so the output is checked
  # rather than the input trusted. A real cleanup stays within a few percent
  # of the raw length — 97-103% across every dictation logged so far — while
  # an answer does not. Rejecting falls back to the raw transcript, which is
  # always better than pasting something the user never said.
  if [ -n "$cleaned" ]; then
    ratio=$((${#cleaned} * 100 / ${#text}))
    if [ "$ratio" -ge 60 ] && [ "$ratio" -le 160 ]; then
      text="$cleaned"
    else
      debug "rejected: cleanup returned ${ratio}% of the raw length"
    fi
  fi
  t_out="$(now)"

  # Borrow the clipboard and hand it back afterwards. Only text is preserved —
  # an image on the clipboard is lost across a dictation.
  #
  # There used to be a second route that synthesized one keystroke per character
  # via wtype. It dropped characters on longer transcripts, because wtype maps
  # the needed characters onto a limited set of virtual keycodes and two
  # adjacent characters sharing a keycode lose one of them. German text with
  # umlauts was the worst case. Pasting replaced it and has held up since.
  previous="$(wl-paste --no-newline 2>/dev/null || true)"
  printf '%s' "$text" | wl-copy --type text/plain

  # Terminals take Ctrl+Shift+V, everything else Ctrl+V, so the paste shortcut
  # depends on the class of the currently focused window.
  class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')" || class=""
  mapfile -t terminals <<<"$DICTATE_TERMINAL_CLASSES"
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

  t_end="$(now)"
  debug "timing  : stop=$((t_stt - t_key))ms stt=$((t_cleanup - t_stt))ms cleanup=$((t_out - t_cleanup))ms out=$((t_end - t_out))ms total=$((t_end - t_key))ms"
else
  # Clean up leftovers from a run that died between start and stop.
  rm -f "$pidfile" "$recfile"
  # 48 kHz although the speech models resample to 16 kHz anyway: sox captures
  # into a fixed 32768-byte PCM block and discards the incomplete block when
  # SIGINT arrives, so every recording loses a random 0..blocklength off its
  # tail. The block is a fixed byte count, so its duration follows the sample
  # rate — 1.024s at 16 kHz, 0.171s at 48 kHz. At 16 kHz the loss exceeded
  # DICTATE_STOP_DELAY often enough to swallow the last words of roughly every
  # fifth dictation; at 48 kHz it always fits inside that delay. Costs 1.9x
  # upload size after ogg encoding, which is why this only became affordable
  # once the recording stopped being uploaded as raw WAV.
  #
  # AUDIODRIVER=alsa because sox's default (pulse) hands audio over with about
  # two seconds of pipeline delay, and everything still in flight is lost when
  # rec is signalled — which ate the last word or two of a dictation no matter
  # how large the block granularity was. Measured against wall clock, the
  # capture deficit is 1.9-2.6s on pulse and ~0.1s on alsa, so DICTATE_STOP_DELAY
  # covers it with room to spare. This still routes through PipeWire via
  # /etc/alsa/conf.d/99-pipewire-default.conf, so device selection is unchanged.
  AUDIODRIVER=alsa rec -q -c 1 -r 48000 "$recfile" &
  echo "$!" >"$pidfile"

  # The popup used to fire the moment rec had been launched, which is not the
  # moment it starts capturing. Whatever was said in between was lost, and it
  # cost the first two words often enough to be noticed. Waiting for evidence
  # that audio is really flowing turns the popup into a signal that can be
  # trusted; the price is that it appears when it appears rather than at once.
  #
  # PipeWire's stream state is the signal. Two other candidates failed: the size
  # of the recording file depends on how well ogg compresses what the microphone
  # picks up, which in a quiet room meant 3.2s instead of the expected 0.7s, and
  # /proc/asound never leaves "closed" because PipeWire owns the hardware device.
  # Measured here: the state flips 99-133ms after launch, and everything spoken
  # from that point on is captured with about 60ms to spare.
  #
  # Matching on node.name rather than on any input stream, because a video call
  # holding the microphone would otherwise satisfy the condition instantly.
  ready=0
  for _ in $(seq 1 100); do
    # The stop branch removes the pidfile before anything else, so a second
    # keypress during the wait leaves the notifications to it.
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
