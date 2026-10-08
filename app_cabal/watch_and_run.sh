#!/usr/bin/env bash
# Runs the Flutter web app in Brave (inside tmux) and auto hot-reloads
# whenever lib/main.dart is saved, so you never have to press "r" manually.
#
# Why tmux: `flutter run` only listens for hot-reload keystrokes when its
# stdin is a real terminal (a TTY). A plain pipe/FIFO is NOT a TTY, so
# Flutter silently ignores anything written to it. tmux gives the flutter
# process a real pseudo-terminal, and `tmux send-keys` lets us "type" into
# it from the outside.
set -euo pipefail

WATCH_FILE="lib/main.dart"
SESSION="inkash_flutter_dev"
BRAVE_PATH="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

if [ ! -f "$WATCH_FILE" ]; then
  echo "Error: $WATCH_FILE not found. Run this script from the project root." >&2
  exit 1
fi

if [ ! -x "$BRAVE_PATH" ]; then
  echo "Error: Brave not found at '$BRAVE_PATH'." >&2
  exit 1
fi

for bin in fswatch tmux; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "$bin not found. Install it with: brew install $bin" >&2
    exit 1
  fi
done

# Point flutter's Chrome-device launcher at Brave instead of Chrome.
export CHROME_EXECUTABLE="$BRAVE_PATH"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n app "flutter run -d chrome"
tmux new-window -t "$SESSION" -n watcher \
  "fswatch -o -l 0.5 '$WATCH_FILE' | while read -r _; do tmux send-keys -t '$SESSION:app' r; done"

cleanup() {
  echo "Stopping..."
  tmux kill-session -t "$SESSION" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "Attaching to tmux session '$SESSION'. Detach with Ctrl+B then D."
echo "Saving $WATCH_FILE will now auto hot-reload the app in Brave."
tmux attach -t "$SESSION:app"
