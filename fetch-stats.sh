#!/bin/sh
# Fetches open GitHub issue count for the current repo and writes to a per-repo cache.
# Cache file is keyed by repo slug so multiple Claude Code instances don't collide.
# Cross-platform: Windows Git Bash PATH additions are only applied when present.
[ -d "/c/Users/Kidriel/AppData/Local/Microsoft/WinGet/Links" ] && export PATH="$PATH:/c/Users/Kidriel/AppData/Local/Microsoft/WinGet/Links"
[ -d "/c/Program Files/GitHub CLI" ] && export PATH="$PATH:/c/Program Files/GitHub CLI"

remote=$(git remote get-url origin 2>/dev/null)
[ -z "$remote" ] && exit 0

# Handles both HTTPS (https://github.com/owner/repo.git) and SSH (git@github.com:owner/repo.git)
repo_path=$(echo "$remote" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
[ -z "$repo_path" ] && exit 0

repo_slug=$(echo "$repo_path" | tr '/' '_')
CACHE_FILE="/tmp/.claude_stats_cache_${repo_slug}"

owner=$(echo "$repo_path" | cut -d'/' -f1)
case "$owner" in
  Jovian-Aurrigo) GH_TOKEN=$(gh auth token --user Jovian-Aurrigo 2>/dev/null) ;;
  Kiriketsuki)    GH_TOKEN=$(gh auth token --user Kiriketsuki 2>/dev/null) ;;
  *) exit 0 ;;
esac
export GH_TOKEN

issue_count=$(gh issue list --repo "$repo_path" --state open --json number 2>/dev/null | jq length 2>/dev/null)

if [ -n "$issue_count" ]; then
  printf '%s\n' "$issue_count" > "$CACHE_FILE"
fi
