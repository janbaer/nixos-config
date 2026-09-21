# Dictation

Push-to-toggle voice dictation. `SUPER + CTRL + D` starts a recording, the same
key stops it. The recording goes to a speech model on OpenRouter, the
transcript goes through a cleanup model, and the result is pasted into the
focused window.

```
rec (sox) → speech model → cleanup model → clipboard → Ctrl+V → clipboard restored
```

## Files

| File | Purpose |
| --- | --- |
| `dictate.nix` | Home Manager module. Packages the script with `writeShellApplication` and exports the configuration as `DICTATE_*` variables. |
| `dictate.sh` | The script. |
| `hosts/common/variables.nix` | The `dictation` block: models and providers. |
| `~/.config/dictate/vocabulary.txt` | Short-lived proper nouns for the cleanup prompt. Read at runtime. |

The script is a separate file and not a Nix string, so shellcheck, syntax
highlighting and `bash dictate.sh` work while editing. `writeShellApplication`
puts the exports in front of the file. The models, the providers and the prompt
have no default in the script and must come from the module, so a stale copy
can never be used. To run the script directly, take those exports from the
installed wrapper (`cat $(command -v dictate)`).

## Configuration

### Models (`hosts/common/variables.nix`)

| Key | Meaning |
| --- | --- |
| `sttModel` | Speech model. |
| `cleanupModel` | Primary cleanup model. |
| `cleanupFallbackModels` | Tried in order when the primary model returns an error. |
| `cleanupProviders` | Preferred provider order, as OpenRouter slugs. Empty means no preference, sorted by throughput. |

The module has no defaults for these keys. A missing key fails the build. A
default would hide a typo in the variables file, and that is how a wrong
cleanup model was used for days without anyone noticing.

### Module options (`dictate.nix`)

| Option | Default | Meaning |
| --- | --- | --- |
| `gopassPath` | `cloud/openrouter/stt` | gopass entry with the OpenRouter API key. |
| `stopDelay` | `0.8` | Seconds to keep recording after the stop press, so the last word is captured. |
| `maxSeconds` | `600` | Hard cap for one recording. |
| `terminalClasses` | `com.mitchellh.ghostty` | Window classes that paste with Ctrl+Shift+V. |
| `restoreDelay` | `0.5` | Seconds to wait after the paste before the old clipboard is restored. |
| `cleanupPrompt` | see module | System prompt for the cleanup model. |

`DICTATE_AUDIO_FORMAT` (default `ogg`) is not an option. Both invocations must
agree on it, so set it in the session environment. nixpkgs' sox cannot write
mp3 or opus, so the alternatives are `wav` and `flac`.

### Vocabulary

The proper nouns in `cleanupPrompt` are stable terms. Names that are only
needed for some weeks (people, companies from an application round) go into
`~/.config/dictate/vocabulary.txt`, one term per line. Blank lines and `#`
lines are skipped. The script appends the terms to the prompt at runtime, so
no rebuild is necessary.

The appended sentence repeats the matching rule and the "output only the
corrected text" rule. It must not depend on the wording of the prompt, which
can be overridden, and the closing instruction must stay at the end of the
prompt.

Rules for the list:

- Only terms the models actually get wrong. A term that is already recognized
  costs prompt length on every dictation and gives nothing.
- The list only helps when the transcript still resembles the term.
  "Environment-Variablen" came back as "Bayern-Programm", and no list repairs
  that.
- The list also pulls the other way: a missing name is rewritten to the entry
  that sounds closest. "Fable 5.1 von Anthropic" arrived as "dem neuen Modell
  von Mistral" because Mistral was listed and Fable was not.
- Speech-only models cannot learn names like "HowCanI" from the sound, because
  it sounds exactly like "how can I". The cleanup model finds it from context.
- `cleanupPrompt` lists the observed wrong spellings of Forgejo and HowCanI,
  because some of them ("for JU") do not resemble the name at all. Keep
  ordinary phrases out of that list: with "for Geo" or "How Can I" in it, the
  model turned "for you" into Forgejo and "how can I help" into "HowCanI help".

## Debugging

`DICTATE_DEBUG=1` writes every stage to `$XDG_RUNTIME_DIR/dictate.log` and
keeps each recording next to it. The key binding is started by Hyprland, so
the variable must be in Hyprland's environment, not in a shell:

```bash
hyprctl eval 'hl.env("DICTATE_DEBUG", "1")'   # on, until logout
hyprctl eval 'hl.env("DICTATE_DEBUG", "0")'   # off
```

All of these lines are only written with `DICTATE_DEBUG=1`:

| Line | Content |
| --- | --- |
| `===` | Time, configured models, audio duration and size. |
| `vocab` | Terms read from the vocabulary file. |
| `audio` | Path of the kept recording. |
| `raw` | Transcript from the speech model. |
| `model` | Cleanup model that actually answered. |
| `cleaned` | Cleanup result. |
| `error` | API error when the transcription or the cleanup failed. |
| `rejected` | The length guard discarded the cleanup. |
| `timing` | Stop delay, transcription, cleanup, paste, total. |

With the kept recording, "a word is missing" becomes answerable: the transcript
alone cannot show whether a word was never captured or captured and not
transcribed. Everything is in tmpfs and gone after logout, but while debug is
on, a plaintext copy and the audio of every dictation exist. That is why it is
off by default.

## Design notes

### Start and stop

- Two key presses are two separate processes. The state is a pidfile with two
  lines: the pid of `rec` and the file it writes.
- A `flock` makes the start/stop decision atomic. Without it, two fast presses
  can both find no pidfile and start two recorders, and one of them runs until
  logout. The lock is released right after the pidfile changes and is never
  held across a wait, so a press during transcription starts a new recording
  at once.
- The recording file contains the pid of the invocation that started it. With
  one shared name, a press during the upload truncated the file about to be
  sent, and the stop branch deleted the new recording under a running `rec`.
- A pid from a stale pidfile can belong to another process by now. Only a live
  process named `rec` counts as a recording, `kill -0` is not enough.
- A pidfile from an older version has no second line. The script then falls
  back to the old fixed file name.
- The stop branch removes the pidfile before the stop delay, so another press
  during transcription starts a new recording.
- `rec` gets SIGINT, not SIGTERM. sox only writes the final header on a clean
  shutdown, and the API rejects a file without it.
- `rec` is a child of the start invocation, so the stop invocation cannot use
  `wait`. `tail --pid` blocks until it exits.

### Recording

- **48 kHz**, although the speech models resample to 16 kHz. sox captures in
  fixed 32768-byte blocks and discards the incomplete block at SIGINT. At
  16 kHz that block is 1.024 s, which was longer than the stop delay and cut
  the last words of about every fifth dictation. At 48 kHz it is 0.171 s.
- **`AUDIODRIVER=alsa`**. With sox's default (pulse), about two seconds of
  audio are still in the pipeline when `rec` is stopped, and they are lost.
  Measured capture deficit: 1.9 to 2.6 s on pulse, about 0.1 s on alsa. ALSA
  still goes through PipeWire via `/etc/alsa/conf.d/99-pipewire-default.conf`,
  so the device selection does not change.
- **Ogg Vorbis** because the upload is the largest part of the wait on a home
  uplink. 8 s of German speech are 258 KB as 16 kHz WAV and 42 KB as ogg, with
  an identical transcript. `rec` encodes during the recording.
- **`trim 0 $DICTATE_MAX_SECONDS`** caps a forgotten recording. tmpfs is RAM,
  at about 35 MB per hour, and one recording ran for nine hours. What was
  recorded is discarded: sending it needs a watchdog and pastes into whatever
  window has focus by then.
- **The "Recording" popup waits for PipeWire.** It used to appear when `rec`
  was launched, which is before it captures, and the first words were lost.
  The script now waits until the PipeWire node `alsa_capture.sox` is
  `running`, 99 to 133 ms after launch. It matches the node name, because a
  video call that holds the microphone would otherwise satisfy the check at
  once. The file size is not a usable signal (it depends on ogg compression),
  and `/proc/asound` stays "closed" because PipeWire owns the device.

### Transcription

- The API key comes from gopass on each run, not from agenix. Dictation is
  interactive, so the gopass agent is unlocked, and the key never exists as a
  file. A locked agent shows a notification instead of ending silently.
- All requests use `--max-time 30`. The pidfile is already gone at this point,
  so a hanging request would hold the clipboard while a new recording starts.
- No language parameter. The model detects the language per recording, and
  German and English work equally well without one.

### Cleanup

- The request is built with `jq --arg`, because the prompt and the transcript
  can contain any character.
- **`reasoning: {enabled: false}`**. Measured on an earlier model
  (deepseek-v4-flash): 284 of 330 completion tokens went into reasoning for a
  punctuation fix, and comparable dictations took 1.0 to 13.2 s. Without
  reasoning, unusual words are a little worse ("publischen" became "publishen"
  instead of "publizieren"), but proper nouns, sentence boundaries and
  negations stay correct. The setting costs nothing on models that do not
  reason.
- **Fallback models.** Mistral serves `mistral-small-2603` from a shared
  upstream pool and returns 429 at times. The request sends `models` with the
  fallbacks, and OpenRouter tries the next model on an error.
  `gemini-2.5-flash` corrected the test dictations correctly.
  `gemini-3.1-flash-lite` made "Hetzner und agenix" from "Hauk und Ei" instead
  of HowCanI, and `mistral-medium-3.1` also invented proper nouns from the
  vocabulary.
- **Provider routing is an order, not `only`.** OpenRouter applies the
  provider list to every model in `models`, so `only: ["mistral"]` makes a
  Gemini fallback unreachable. As a consequence, the primary model can also go
  to a provider other than Mistral if one offers it. With an empty list, the
  request sorts by
  throughput: identical 120-token requests took 2.5 s on one provider and
  36.6 s on another. Throughput and not latency, because the whole output is
  needed.
- **The full response is kept.** Reducing it to the content at once made every
  API error look like an empty cleanup, and the 429s were invisible. A failed
  cleanup now shows a notification and pastes the raw transcript. The
  transcription does the same: an API error shows "transcription failed", and
  only a response without text shows "no transcription".
- **Length guard.** On about a fifth of the dictations that end in a question
  to an assistant, the model answers the question instead of cleaning it, in
  one case with a Chinese "I have no information on that". This happened with
  and without reasoning, and changes to the prompt did not help. A real cleanup
  stays at 97 to 103 % of the raw length, so a result outside 60 to 160 % is
  discarded and the raw transcript is pasted.

### Paste

- The script borrows the clipboard: it saves the current text, copies the
  transcript, sends the paste shortcut and restores the old text. An image on
  the clipboard is lost.
- Earlier versions typed the text with `wtype`, one key per character. That
  dropped characters in longer transcripts, because wtype maps characters onto
  a limited set of virtual keycodes, and two adjacent characters with the same
  keycode lose one. German text with umlauts was the worst case.
- Terminals use Ctrl+Shift+V. The script reads the class of the focused window
  from `hyprctl` and compares it with `terminalClasses`.
- cliphist records the transcript in the clipboard history. The script removes
  that entry again, but only if the newest entry is still the transcript.
- Every command between the copy and the restore has `|| true`, so a failing
  `wtype` (screen locked, virtual keyboard denied) cannot end the script before
  the old clipboard is back.
