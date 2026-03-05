#!/usr/bin/env bash
# claude-statusline quick-init
# Clones the statusline repo into ~/.claude/statusline/ and wires up settings.json.
# Safe to re-run: skips clone if already present, skips hooks if already wired.
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/Kiriketsuki/claude-statusline/main/init.sh)
#   or:  bash init.sh  (if you've already cloned)

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
STATUSLINE_DIR="$CLAUDE_DIR/statusline"
SETTINGS="$CLAUDE_DIR/settings.json"
REPO="https://github.com/Kiriketsuki/claude-statusline.git"

SL_CMD="bash ~/.claude/statusline/statusline-command.sh"
FETCH_USAGE="bash ~/.claude/statusline/fetch-usage.sh > /dev/null 2>&1 &"
FETCH_STATS="bash ~/.claude/statusline/fetch-stats.sh > /dev/null 2>&1 &"

# --- helpers ---
info()  { printf '  %s\n' "$*"; }
ok()    { printf '[ok] %s\n' "$*"; }
skip()  { printf '[--] %s\n' "$*"; }
die()   { printf '[!!] %s\n' "$*" >&2; exit 1; }

# --- preflight ---
command -v git >/dev/null 2>&1 || die "git not found. Install git first."
command -v jq  >/dev/null 2>&1 || die "jq not found. Install jq first (brew install jq / apt install jq / winget install jqlang.jq)."

printf '\nclaude-statusline init\n'
printf '======================\n\n'

# --- step 1: clone or update ---
if [ -d "$STATUSLINE_DIR/.git" ]; then
  skip "statusline already cloned at $STATUSLINE_DIR"
  info "Pulling latest..."
  git -C "$STATUSLINE_DIR" pull --ff-only --quiet && ok "Up to date." || info "Pull skipped (local changes or diverged)."
else
  info "Cloning into $STATUSLINE_DIR ..."
  mkdir -p "$CLAUDE_DIR"
  git clone --quiet "$REPO" "$STATUSLINE_DIR"
  ok "Cloned."
fi

# --- step 2: ensure settings.json exists ---
if [ ! -f "$SETTINGS" ]; then
  printf '{}' > "$SETTINGS"
  info "Created $SETTINGS"
fi

# --- step 3: backup ---
cp "$SETTINGS" "${SETTINGS}.bak"
info "Backup: ${SETTINGS}.bak"

# --- step 4: merge settings via jq ---
# statusLine: always set (safe to overwrite, it's a renderer command)
# PreToolUse / Stop hooks: append only if fetch-usage.sh not already referenced
jq \
  --arg sl_cmd    "$SL_CMD" \
  --arg fetch_u   "$FETCH_USAGE" \
  --arg fetch_s   "$FETCH_STATS" \
  '
  # Wire up the status line renderer
  .statusLine = {"type": "command", "command": $sl_cmd} |

  # PreToolUse: add fetch-usage hook if not already present
  if ((.hooks.PreToolUse // []) | any(.[]; (.hooks // []) | any(.[]; .command | strings | test("fetch-usage\\.sh")))) then
    .
  else
    .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [
      {"matcher": "", "hooks": [{"type": "command", "command": $fetch_u}]}
    ])
  end |

  # Stop: add both fetchers if not already present
  if ((.hooks.Stop // []) | any(.[]; (.hooks // []) | any(.[]; .command | strings | test("fetch-usage\\.sh")))) then
    .
  else
    .hooks.Stop = ((.hooks.Stop // []) + [
      {"matcher": "", "hooks": [
        {"type": "command", "command": $fetch_u},
        {"type": "command", "command": $fetch_s}
      ]}
    ])
  end
  ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

ok "settings.json updated."

printf '\nDone. Restart Claude Code to activate the status line.\n\n'
printf 'Optional: set CHRYSAKI_BAR_STYLE in your shell profile.\n'
printf '  export CHRYSAKI_BAR_STYLE=hex   # hex | diamond | circle | wave | block\n\n'
