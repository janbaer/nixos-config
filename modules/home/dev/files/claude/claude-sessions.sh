# Usage: claude-sessions [start|restart]
# Makes sure a claude session runs in every directory listed in the config
# file, one herdr tab per directory, labelled with the directory name.
# Sessions are started with --continue. restart quits running sessions first;
# only idle or done sessions are quit, all others are left alone.

conf="${CLAUDE_SESSIONS_CONF:-$HOME/.config/claude-sessions/config.yaml}"
workspace="projects"

usage() {
  echo "usage: $(basename "$0") [start|restart]" >&2
  exit 1
}

dirs() {
  [ -f "$conf" ] || { echo "missing config: $conf" >&2; exit 1; }
  yq '.directories[]' "$conf" |
    while read -r d; do printf '%s\n' "${d/#\~/$HOME}"; done
}

claude_pane() {
  herdr pane list | gojq -r --arg d "$1" \
    '[.result.panes[] | select(.agent == "claude" and .cwd == $d)][0].pane_id // empty'
}

pane_status() {
  herdr agent list | gojq -r --arg p "$1" \
    '.result.agents[] | select(.pane_id == $p) | .agent_status'
}

find_tab() {
  herdr tab list | gojq -r --arg l "$1" --arg w "$ws" \
    '[.result.tabs[] | select(.label == $l and .workspace_id == $w)][0].tab_id // empty'
}

free_pane() {
  herdr pane list | gojq -r --arg t "$1" --arg d "$2" \
    '[.result.panes[] | select(.tab_id == $t and .agent == null)]
     | map(select(.cwd == $d))[0].pane_id // empty'
}

stop() {
  local pane=$1 running
  herdr pane send-text "$pane" "/exit" >/dev/null || return 1
  herdr pane send-keys "$pane" enter >/dev/null || return 1
  for _ in $(seq 20); do
    sleep 0.5
    running=$(claude_pane "$2") || return 1
    [ -z "$running" ] && return 0
  done
  return 1
}

launch() {
  local dir=$1 name tab pane
  name=$(basename "$dir")
  tab=$(find_tab "$name") || return 1
  if [ -z "$tab" ]; then
    herdr tab create --workspace "$ws" --cwd "$dir" --label "$name" --no-focus >/dev/null || return 1
    tab=$(find_tab "$name") || return 1
  fi
  pane=$(free_pane "$tab" "$dir") || return 1
  [ -n "$pane" ] || { echo "no free pane in tab $name" >&2; return 1; }
  herdr pane run "$pane" "claudeRun --continue || claudeRun" >/dev/null
}

mode=${1:-start}
case "$mode" in
  start | restart) ;;
  *) usage ;;
esac

ws=$(herdr workspace list | gojq -r --arg l "$workspace" \
  '[.result.workspaces[] | select(.label == $l)][0].workspace_id // empty')
[ -n "$ws" ] || { echo "herdr workspace '$workspace' not found" >&2; exit 1; }

dirlist=$(dirs)
[ -n "$dirlist" ] || { echo "no directories in $conf" >&2; exit 1; }

while read -r dir; do
  if [ ! -d "$dir" ]; then
    echo "not a directory: $dir" >&2
    continue
  fi
  pane=$(claude_pane "$dir")
  if [ -n "$pane" ]; then
    if [ "$mode" = start ]; then
      echo "running: $dir"
      continue
    fi
    status=$(pane_status "$pane")
    if [ "$status" != idle ] && [ "$status" != "done" ]; then
      echo "$status, left alone: $dir" >&2
      continue
    fi
    if ! stop "$pane" "$dir"; then
      echo "did not exit: $dir" >&2
      continue
    fi
  fi
  if launch "$dir"; then
    echo "started: $dir"
  else
    echo "failed: $dir" >&2
  fi
done <<<"$dirlist"
