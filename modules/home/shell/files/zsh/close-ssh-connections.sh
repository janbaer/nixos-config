#!/usr/bin/env bash

# Multiplexing masters title themselves "ssh: <control path> [mux]"
GREP_COMMAND='^ssh: .*\[mux\]$'

# Find the process IDs of the current user matching the grep command
CANDIDATES=$(pgrep -u "$(id -u)" -f "$GREP_COMMAND")

# Keep only real OpenSSH clients
PIDS=""
for PID in $CANDIDATES; do
  if [[ "$(basename "$(readlink "/proc/$PID/exe")")" == "ssh" ]]; then
    PIDS="$PIDS $PID"
  fi
done

# Check if any matching processes were found
if [[ -z $PIDS ]]; then
  echo "No processes found matching the grep command: $GREP_COMMAND"
  exit 0
fi

# Iterate over each process ID and terminate the processes
failed=0
for PID in $PIDS; do
  echo "Killing process with PID: $PID"
  kill "$PID" || failed=1
done

if [[ $failed -ne 0 ]]; then
  echo "Some SSH connections could not be closed" >&2
  exit 1
fi

echo "***Closed all open SSH connections***"
