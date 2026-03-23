# ai-session-checkpoint

**Never lose AI coding session context again.**

When your Claude Code context fills up or your Cursor tab crashes, all the context vanishes. `ai-session-checkpoint` silently saves session state to a folder — so your next session picks up exactly where you left off. Put that folder in Google Drive or iCloud and it syncs across machines automatically.

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
| **Cross-machine** | Put checkpoint folder in Google Drive / iCloud — syncs automatically |
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

### Local folder (default)

Checkpoints go to `~/.ai-checkpoints/my-project/`. Works immediately, zero setup.

### Cloud sync (Google Drive / iCloud)

To sync checkpoints across machines, put the folder in Google Drive or iCloud:

```bash
# 1. Create a folder in Google Drive (one time)
mkdir -p ~/Google\ Drive/My\ Drive/ClaudeCode/

# 2. Run install.sh from your project and enter the path when prompted
cd ~/my-project
curl -fsSL https://raw.githubusercontent.com/gokks8142/ai-session-checkpoint/main/install.sh | bash

# When asked "Where should checkpoints be stored?", enter:
#   ~/Google Drive/My Drive/ClaudeCode/
```

That's it. Checkpoints sync automatically via Google Drive. On your other machine, create the same symlink and you have full context.

### Obsidian (optional bonus)

If you already use [Obsidian](https://obsidian.md), you can point your vault at the same Google Drive folder. This gives you search, graph view, and backlinks across your checkpoints — but it's purely optional. The tool works identically with or without Obsidian.

## Link a Project

The installer handles this automatically. If you need to do it manually:

```bash
# Symlink your project to the checkpoint folder
ln -s ~/Google\ Drive/My\ Drive/ClaudeCode/my-project  ~/my-project/.checkpoints
```

To verify:
```bash
ls -la .checkpoints/
# Should show: project-state.md, sessions/, decisions.md, problems.md
```

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

To completely remove ai-session-checkpoint from a project:

```bash
# 1. Remove the symlink from your project
rm .checkpoints

# 2. Remove checkpoint instructions from CLAUDE.md
#    Delete the lines that start with "At session start, read .checkpoints..."
#    and "When the user says checkpoint..."

# 3. Remove the Claude Code skill
rm -rf ~/.claude/skills/ai-session-checkpoint/

# 4. (Optional) Delete your checkpoint files
rm -rf ~/.ai-checkpoints/my-project/
```

**Note:** Step 4 is optional. Your checkpoint files contain useful session history — you may want to keep them even after uninstalling.

## License

MIT
