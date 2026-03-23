# ai-session-checkpoint

**Never lose AI coding session context again.**

When your Claude Code context fills up or your Cursor tab crashes, all the context vanishes. `ai-session-checkpoint` silently saves session state to a local folder or Obsidian vault — so your next session picks up exactly where you left off.

## Quick Start (30 seconds)

```bash
cd ~/my-project

# Option 1: Shell script (zero dependencies)
curl -fsSL https://raw.githubusercontent.com/gokks8142/ai-session-checkpoint/main/install.sh | bash

# Option 2: npx (Node.js users)
npx ai-session-checkpoint init
```

That's it. Open your AI editor, start coding. Checkpoints happen automatically.

## What It Does

| Feature | How |
|---------|-----|
| **Auto-checkpoint** | Background agent saves every 20 min (Claude Code) |
| **Manual checkpoint** | Say "checkpoint" in any AI editor |
| **Session recovery** | New sessions read `.checkpoints/` on start — full context |
| **Cross-editor** | Same `.checkpoints/` folder works in Claude Code + Cursor |
| **Cross-machine** | Obsidian vault syncs via Google Drive / iCloud |
| **Change detection** | Skips if no files changed — no noise from read-only work |
| **Smart retention** | Keeps recent detail, compresses old history, max 50 files |

## How It Works

```
my-project/
├── .checkpoints/               ← symlink to checkpoint storage
│   ├── project-state.md        ← current project state (always up-to-date)
│   ├── sessions/
│   │   ├── 2026-03-21-10-30.md ← auto-checkpoint
│   │   └── 2026-03-21-11-15.md ← manual checkpoint
│   ├── decisions.md            ← architecture decisions log
│   └── problems.md             ← open issues / blockers
├── CLAUDE.md                   ← tells Claude to read/write .checkpoints/
└── ... (your code)
```

1. **On session start**: AI reads `project-state.md` + latest session file → full context
2. **Every 20 min**: Background agent checks `git diff`, writes session snapshot if changes detected
3. **On "checkpoint"**: Immediate save with summary confirmation
4. **New session**: Reads checkpoints, picks up where you left off

## Storage Options

**Local folder** (default — zero dependencies):
```
~/.ai-checkpoints/my-project/
```

**Obsidian vault** (for cross-machine sync):
```
Obsidian Vault/Org/ClaudeCode/my-project/
```

Switch anytime: `npx ai-session-checkpoint migrate --to obsidian`

## Supported Editors

| Editor | Auto-checkpoint | Manual checkpoint | Config file |
|--------|:-:|:-:|---|
| Claude Code | ✅ | ✅ | `CLAUDE.md` |
| Cursor | — | ✅ | `.cursorrules` |

The checkpoint format is editor-agnostic — any AI editor that reads files can use it.

## What Gets Saved

**Session file** (`sessions/YYYY-MM-DD-HH-MM.md`):
- Summary of what was accomplished
- Files changed and why
- Decisions made
- Open items and next steps

**Project state** (`project-state.md`):
- What the project is and tech stack
- What's built and working
- What's in progress
- Key files and their purposes
- Known issues

## Smart Retention

Checkpoints don't pile up forever:

| Time window | Rule |
|-------------|------|
| Last 24 hours | Keep all |
| Last 7 days | Keep 1 per day |
| Last 30 days | Keep 1 per week |
| Older | Delete |

Hard cap: **50 files max** (configurable). Oldest deleted on rollover.

## Uninstall

```bash
rm .checkpoints                    # Remove symlink
# Remove checkpoint lines from CLAUDE.md or .cursorrules
# Optionally delete ~/.ai-checkpoints/my-project/
```

## License

MIT
