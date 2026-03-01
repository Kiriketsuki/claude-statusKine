# claude-statusline

A two-line Claude Code status bar displaying model, workspace context, API usage, and vault inbox depth. Built for the [obKidian](https://github.com/Kiriketsuki/obKidian) vault but usable in any Claude Code setup.

## Scripts

| Script | Role |
|:---|:---|
| `statusline-command.sh` | Main renderer — reads caches and emits the formatted two-line status bar |
| `fetch-usage.sh` | Background fetcher — polls the Anthropic API for 5h/7d usage and writes to `/tmp/.claude_usage_cache` |
| `fetch-stats.sh` | Background fetcher — polls GitHub for open issue count per repo and writes to `/tmp/.claude_stats_cache_{slug}` |

## Status Line Layout

```
<model> | <folder> • <branch> ↑<unsynced>
<5h %>  •  <7d %> | ctx <pct> (<tokens>) | issues: <n> • inbox: <n>
```

Colours follow the Chrysaki palette with semantic thresholds:
- Context: orange >= 50%, red >= 128k tokens
- 5h usage: yellow >= 50%, red >= 75%

## Setup

Install as a submodule inside your `~/.claude` directory (or wherever your Claude config lives):

```bash
# From your Claude config directory (e.g. ~/dev/obKidian/000-System/Agents/Claude)
git submodule add https://github.com/Kiriketsuki/claude-statusline.git statusline
```

Wire up `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline/statusline-command.sh"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/statusline/fetch-usage.sh > /dev/null 2>&1 &" }]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash ~/.claude/statusline/fetch-usage.sh > /dev/null 2>&1 &" },
          { "type": "command", "command": "bash ~/.claude/statusline/fetch-stats.sh > /dev/null 2>&1 &" }
        ]
      }
    ]
  }
}
```

## Dependencies

- `jq` — JSON parsing
- `curl` — Anthropic API calls (fetch-usage.sh)
- `gh` — GitHub CLI for issue counts (fetch-stats.sh); must be authenticated
- `git` — branch and commit info

## Cache Files

| File | Written by | Read by | Content |
|:---|:---|:---|:---|
| `/tmp/.claude_usage_cache` | `fetch-usage.sh` | `statusline-command.sh` | 5h%, 7d%, reset timestamps |
| `/tmp/.claude_stats_cache_{slug}` | `fetch-stats.sh` | `statusline-command.sh` | Open issue count |

## Platform Compatibility

Compatible with Linux, macOS, and Windows Git Bash. The `date -d` (GNU) vs `date -j` (BSD) difference for reset time parsing is handled with a dual-path fallback in `statusline-command.sh`.
