# ai-session-checkpoint

**Product Definition**
Never Lose AI Coding Session Context Again

**Version:** 1.0 | **Date:** March 2026 | **License:** MIT Open Source

## 1. Executive Summary

`ai-session-checkpoint` is an open-source tool that automatically snapshots AI coding session state — so when sessions crash, context fills up, or you switch editors or machines, your next session picks up exactly where you left off.

Today, AI-assisted coding sessions are **ephemeral**. When a Claude Code context window fills up or a Cursor session crashes, all the context — what was built, what decisions were made, what problems were encountered — vanishes. The developer must re-explain everything from scratch. This wastes time, loses decisions, and breaks flow.

`ai-session-checkpoint` solves this with a **background sub-agent** that silently snapshots session state every 20 minutes to a local folder or Obsidian vault. The developer is never interrupted. The next session — in any AI editor, on any machine — reads the checkpoint and resumes with full context.

### Design Principles

| # | Principle | What it means |
|---|-----------|---------------|
| 1 | **Easy Setup** | One command to install. No config files, no manual steps. |
| 2 | **AI Editor Agnostic** | Works with Claude Code, Cursor, and any future AI editor. Same format, same protocol. |
| 3 | **Automatic Snapshotting** | A background sub-agent saves every 20 minutes without interrupting the builder. |
| 4 | **Git Ready** | Clone the repo, run init, start coding. MIT licensed. |
| 5 | **Storage Agnostic** | Works with a plain local folder OR an Obsidian vault. No dependencies forced. |

### Scope — v1.0

**In Scope:**
- Automatic background checkpointing every 20 minutes (Claude Code)
- Manual checkpointing via "checkpoint" command (Claude Code + Cursor)
- Session recovery on new session start (reads project state + latest session file)
- One-command setup (`curl` or `npx`)
- Two storage options: plain local folder or Obsidian vault
- Two AI editor support: Claude Code (auto + manual) and Cursor (manual only)
- **Change detection** — only snapshot when files have actually changed (`git diff`), skip if idle or read-only
- **Smart retention** — tiered policy (keep all for 24h, daily for 7d, weekly for 30d, delete older) with hard cap of 50 files
- Session file generation with summary, files changed, decisions, open items
- Project state file — holistic rewrite on each checkpoint
- `.checkpoints` symlink connecting project to checkpoint folder
- Editor config injection (CLAUDE.md / .cursorrules)
- Claude Code skill packaging for easy distribution
- Templates for new project checkpoint folders
- MIT open source license

**Out of Scope (Future):**
- Automatic checkpointing in Cursor (requires Cursor to support background agents)
- Windsurf, Copilot, or other AI editor support (protocol is editor-agnostic — community can add)
- Web dashboard for viewing checkpoints across projects
- Team checkpoint aggregation / analytics
- Git integration (auto-commit checkpoints to a branch)
- Conflict resolution when multiple sessions checkpoint simultaneously
- Checkpoint encryption or access control

## 2. Problem Statements

### PS-1: Context Loss on Session End

**Persona:** Full-stack developer using Claude Code

> *"I spent 3 hours building a feature with Claude Code. Context window filled up. Started a new session — Claude had no idea what we'd done. I spent 20 minutes re-explaining the architecture, the files we'd changed, and the decisions we'd made. This happens every day."*

**Impact:** 15-30 minutes lost per session restart. Across a team, this compounds to hours per week.

### PS-2: Sessions Crash Without Warning

**Persona:** DevOps engineer using Cursor

> *"My Cursor tab crashed mid-conversation. The entire session — all the debugging context, the root cause we'd identified, the fix we were halfway through — gone. I had to start over from the error message."*

**Impact:** Complete loss of diagnostic context. Debugging restarts from zero.

### PS-3: No Cross-Editor Context Portability

**Persona:** Developer who switches between Claude Code and Cursor

> *"I use Claude Code for complex architecture work and Cursor for quick edits. But context from one doesn't carry to the other. Each editor starts fresh. I'm repeating myself constantly."*

**Impact:** AI editors are isolated silos. Developers who use multiple tools pay a context tax.

### PS-4: No Cross-Machine Continuity

**Persona:** Remote developer with multiple workstations

> *"I started a project on my office Mac, then picked it up on my laptop at home. Claude had no idea what I'd done earlier. All the session context was local to the office machine."*

**Impact:** Work-from-anywhere breaks down when context is machine-local.

## 3. Use Cases

### UC-1: Automatic Session Checkpoint (Background)

| | |
|---|---|
| **Actor** | Background sub-agent |
| **Trigger** | Every 20 minutes during an active AI coding session (only if files changed) |

**Flow:**
1. Developer works normally in Claude Code or Cursor
2. Every 20 minutes, the background sub-agent silently activates
3. Agent checks `git diff` — if no file changes since last checkpoint, skips silently
4. If changes detected: agent reads current project state and recent changes
5. Agent writes an incremental session summary to `sessions/YYYY-MM-DD-HH-MM.md`
6. Agent updates `project-state.md` with current reality
7. Agent runs retention sweep (deletes old session files per tiered policy)
8. Agent completes silently — developer sees nothing, no interruption

**Outcome:** Session state is continuously saved without any developer action. Read-only work (searching, exploring, reading docs) produces zero checkpoints.

### UC-2: Manual Checkpoint

| | |
|---|---|
| **Actor** | Developer |
| **Trigger** | Developer says "checkpoint" or "save progress" |

**Flow:**
1. Developer reaches a milestone or wants to explicitly save state
2. Developer types "checkpoint" in the AI chat
3. Agent immediately writes a session summary and updates project state
4. Developer receives confirmation with summary of what was saved

**Outcome:** On-demand state capture for important milestones.

### UC-3: Session Recovery (Cold Start)

| | |
|---|---|
| **Actor** | Developer starting a new AI session |
| **Trigger** | New session opened in any AI editor |

**Flow:**
1. Developer opens a new Claude Code or Cursor session in a project
2. AI reads `.checkpoints/project-state.md` (current state) and the latest session file
3. AI immediately has context: what's been built, what's in progress, key files, known issues
4. Developer continues working without re-explaining anything

**Outcome:** Zero cold-start penalty. New sessions pick up exactly where the last one left off.

### UC-4: Cross-Editor Continuity

| | |
|---|---|
| **Actor** | Developer switching between Claude Code and Cursor |
| **Trigger** | Developer opens a different AI editor on the same project |

**Flow:**
1. Developer finishes work in Claude Code (checkpoint saved)
2. Developer opens the same project in Cursor
3. Cursor reads `.checkpoints/project-state.md` via `.cursorrules`
4. Full context is available — decisions, changes, open items

**Outcome:** Seamless context handoff between AI editors.

### UC-5: Cross-Machine Continuity

| | |
|---|---|
| **Actor** | Developer switching machines |
| **Trigger** | Developer opens project on a different computer |

**Flow:**
1. Developer works on office Mac — checkpoints saved to Obsidian vault (Google Drive synced)
2. Developer goes home, opens project on laptop
3. Google Drive syncs the vault — `.checkpoints` symlink points to same cloud-synced folder
4. New session reads the latest checkpoint — full context available

**Outcome:** Work follows the developer across machines via cloud-synced storage.

### UC-6: Team Context Sharing

| | |
|---|---|
| **Actor** | Team of developers working on the same project |
| **Trigger** | Developer wants to see what a teammate worked on |

**Flow:**
1. Team uses a shared checkpoint folder (Git repo or shared cloud folder)
2. Developer A checkpoints their session
3. Developer B opens the project and reads the session files
4. Developer B understands what A worked on, what decisions were made, and what's pending

**Outcome:** Lightweight knowledge sharing without standups or handoff docs.

## 4. User Experience

### Workflow 1: First-Time Setup

**Time:** 30 seconds | **Effort:** One command

```bash
cd ~/my-project
curl -fsSL https://raw.githubusercontent.com/<user>/ai-session-checkpoint/main/install.sh | bash
```

**What the user sees:**
```
ai-session-checkpoint v1.0

? Where should checkpoints be stored?
  > Local folder (~/.ai-checkpoints/)
    Obsidian vault (auto-detected: /Users/you/.../MyVault)

? Project name? (my-project)
  > my-project

? AI editor detected: Claude Code. Configure it?
  > Yes

✓ Created:     ~/.ai-checkpoints/my-project/
✓ Templates:   project-state.md, decisions.md, problems.md, sessions/
✓ Symlink:     .checkpoints → ~/.ai-checkpoints/my-project/
✓ CLAUDE.md:   Added checkpoint instructions
✓ Skill:       Installed to ~/.claude/skills/obsidian-checkpoint/

Done! Auto-checkpointing starts on your next Claude Code session.
```

**After setup, the project looks like:**
```
my-project/
├── .checkpoints → ~/.ai-checkpoints/my-project/  (symlink)
├── CLAUDE.md    (now includes checkpoint instructions)
└── ... (your code)
```

**The user never touches checkpoint files again.** Everything is automatic from here.

### Workflow 2: Working with Auto-Checkpoints (Daily Use)

**Time:** Zero | **Effort:** Zero — completely invisible

1. Developer opens Claude Code and starts working
2. Claude reads `.checkpoints/project-state.md` on session start — has full context
3. Developer codes, debugs, reviews — normal workflow
4. **Every 20 minutes**, background sub-agent silently activates:

```
[Background — user sees nothing]

Sub-agent checks:
  - git diff --stat → any file changes?
  - IF no changes → skip, go back to sleep
  - IF changes detected → proceed:

Sub-agent reads:
  - .checkpoints/project-state.md (current state)
  - git diff (what changed since last checkpoint)

Sub-agent writes:
  - .checkpoints/sessions/2026-03-21-14-20.md (session snapshot)
  - .checkpoints/project-state.md (updated state)

Sub-agent completes. User is unaware.
```

5. Developer continues working. Checkpoints accumulate silently.
6. If the session crashes or context fills up — **no data is lost**

### Workflow 3: Manual Checkpoint

**Time:** 5 seconds | **Effort:** One word

Developer reaches a milestone and wants to explicitly save:

```
Developer: "checkpoint"

Claude: ✓ Session saved to .checkpoints/sessions/2026-03-21-15-45.md
        ✓ Project state updated

        Summary:
        - Implemented user authentication with JWT
        - Added login/register API endpoints
        - Created auth middleware
        - Open: need to add password reset flow
```

### Workflow 4: Session Recovery (New Session)

**Time:** Instant | **Effort:** Zero

Developer starts a new Claude Code session (after crash, context fill, or next day):

```
Claude: [reads .checkpoints/project-state.md]
        [reads .checkpoints/sessions/2026-03-21-15-45.md (latest)]

Claude: "Welcome back. Here's where we left off:
         - Authentication is implemented (JWT + middleware)
         - Login/register endpoints are working
         - Still need: password reset flow
         - Key files: server/auth.ts, server/middleware.ts

         Ready to continue with the password reset flow?"
```

**No re-explanation needed.** The developer picks up exactly where they left off.

### Workflow 5: Switching AI Editors

Developer finishes in Claude Code, opens same project in Cursor:

```
Cursor: [reads .checkpoints/project-state.md via .cursorrules]

Cursor: "I can see from the project state that authentication
         was recently implemented with JWT. The password reset
         flow is the next open item. Want to start there?"
```

Same checkpoint folder, same files — works in both editors.

### Workflow 6: Switching Machines (Obsidian Users)

Developer works on office Mac, then switches to laptop at home:

```
Office Mac:
  .checkpoints → ~/GoogleDrive/.../MyVault/Org/ClaudeCode/my-project/
  [Developer works, checkpoints accumulate, Google Drive syncs]

Laptop at home:
  .checkpoints → ~/GoogleDrive/.../MyVault/Org/ClaudeCode/my-project/
  [Same symlink, same vault, synced via Google Drive]
  [New session reads latest checkpoint — full context available]
```

### Workflow 7: Viewing Checkpoint History

Developer wants to see what happened across sessions:

```
ls .checkpoints/sessions/

2026-03-19-09-15.md   # Monday morning
2026-03-19-09-35.md   # Auto-checkpoint
2026-03-19-10-00.md   # Manual checkpoint (feature done)
2026-03-20-14-10.md   # Tuesday afternoon
2026-03-20-14-30.md   # Auto-checkpoint
2026-03-21-10-00.md   # Wednesday morning
```

Each file is a self-contained summary — readable in any text editor, Obsidian, or GitHub.

### Workflow 8: Migrating from Local to Obsidian

Developer starts with a local folder, later decides to use Obsidian for cross-machine sync:

```bash
npx ai-session-checkpoint migrate --to obsidian
```

All existing checkpoint files move into the Obsidian vault. The symlink updates. History is preserved — nothing is lost.

## 5. Architecture

### Background Sub-Agent Model

```
┌─────────────────────────────────────────┐
│         User's Main Session             │
│  (coding, debugging, reviewing)         │
│                                         │
│  The user sees NOTHING from the         │
│  checkpoint agent. Zero interruption.   │
└──────────────────┬──────────────────────┘
                   │
            (every 20 min)
                   │
┌──────────────────▼──────────────────────┐
│      Background Checkpoint Sub-Agent     │
│  (runs in its own isolated space)        │
│                                          │
│  1. Check git diff — any changes?        │
│  2. IF no changes → skip (no-op)         │
│  3. IF changes → read project state      │
│  4. Write sessions/YYYY-MM-DD-HH-MM.md  │
│  5. Update project-state.md              │
│  6. Run retention sweep                  │
│  7. Silently complete                    │
└──────────────────────────────────────────┘
```

### Checkpoint Folder Structure (per project)

The same folder structure — regardless of where it lives:

```
<ProjectName>/
├── project-state.md      # Current state (always up-to-date)
├── sessions/
│   ├── 2026-03-21-10-30.md   # Auto-checkpoint
│   ├── 2026-03-21-10-50.md   # Auto-checkpoint
│   └── 2026-03-21-11-15.md   # Manual checkpoint
├── decisions.md           # Architecture decisions log
└── problems.md            # Open issues / blockers
```

### Two Storage Options

**Option A: Plain Local Folder** (default — no dependencies)
```
~/.ai-checkpoints/
└── MyProject/
    ├── project-state.md
    ├── sessions/
    ├── decisions.md
    └── problems.md
```
- Just markdown files in a local folder
- Works immediately, zero dependencies
- User can optionally sync via Git, Dropbox, etc.

**Option B: Obsidian Vault** (for cross-machine access)
```
Obsidian Vault/
└── Org/ClaudeCode/
    └── MyProject/
        ├── project-state.md
        ├── sessions/
        ├── decisions.md
        └── problems.md
```
- Same files, but inside an Obsidian vault
- Syncs via Google Drive / iCloud / Obsidian Sync — enables cross-machine continuity
- Bonus: Obsidian's search, graph view, backlinks, and tags

### How It Connects to the Project

A `.checkpoints` symlink connects the project to its checkpoint folder:

```
Project repo (e.g. ~/vibecode/MyProject/)
├── .checkpoints → symlink to checkpoint folder (local or Obsidian)
├── CLAUDE.md → tells AI to read/write .checkpoints/
└── .cursorrules → same instructions for Cursor
```

### Change Detection — Only Snapshot When Needed

```
Agent wakes up (every 20 min):
  1. Run git diff --stat — any file changes since last checkpoint?
  2. Check last checkpoint timestamp vs. last git activity
  3. IF no changes → skip, do nothing, go back to sleep
  4. IF changes detected → proceed with snapshot
```

**What DOES trigger a snapshot:**
- Files created, modified, or deleted (`git diff` shows changes)
- New git commits since last checkpoint
- Architecture decisions made (even if no code yet — captured via manual "checkpoint")

**What does NOT trigger a snapshot:**
- Read-only commands (grep, search, file reads, code exploration)
- Idle session (user is reading, thinking, not coding)
- No files changed since last checkpoint
- Questions and answers (no state change)
- Browsing documentation or reviewing PRs

### Smart Retention — Deltas, Not Infinite Growth

```
Retention Policy:
┌─────────────────────────────────────────────┐
│  Last 24 hours    → Keep ALL snapshots      │
│  Last 7 days      → Keep 1 per day (latest) │
│  Last 30 days     → Keep 1 per week         │
│  Older than 30d   → Delete (or archive)     │
└─────────────────────────────────────────────┘

Hard cap: 50 session files max (configurable rollover)
```

Configurable per project:
```
max_checkpoints: 50         # hard cap — rollover when hit
retention_24h: all          # keep everything
retention_7d: daily         # 1 per day
retention_30d: weekly       # 1 per week
retention_older: delete     # or "archive" or "keep"
```

### Multi-Editor Support

| Concept | Claude Code | Cursor |
|---------|-------------|--------|
| Project instructions | `CLAUDE.md` | `.cursorrules` |
| Auto-checkpointing | Background sub-agent (scheduled task) | Not available (manual only) |
| Manual checkpointing | "checkpoint" command | "checkpoint" command |
| Skills | `~/.claude/skills/` | N/A (use .cursorrules) |

The checkpoint format is editor-agnostic. Same `.checkpoints/` folder, same markdown files — works in both editors.

## 6. Requirements Summary

| # | Requirement | Detail | Priority |
|---|------------|--------|----------|
| 1 | **One-Command Setup** | `curl` or `npx` installs everything: checkpoint folder, symlink, editor config, skill. Interactive prompts for storage location and editor. | P1 — MVP |
| 2 | **Background Auto-Checkpoint** | Scheduled sub-agent runs every 20 minutes in isolated space. Zero interruption to user's main session. | P1 — MVP |
| 3 | **Change Detection** | Check `git diff` before each snapshot. Skip if no files changed. Read-only commands produce zero checkpoints. | P1 — MVP |
| 4 | **Manual Checkpoint** | User says "checkpoint" — immediate snapshot with summary confirmation. Works in Claude Code and Cursor. | P1 — MVP |
| 5 | **Session Recovery** | On new session start, AI reads `project-state.md` and latest session file. Full context without re-explanation. | P1 — MVP |
| 6 | **Local Folder Storage** | Default storage in `~/.ai-checkpoints/<project>/`. Zero dependencies, zero setup beyond init. | P1 — MVP |
| 7 | **Obsidian Vault Storage** | Optional storage in Obsidian vault for cross-machine sync. Auto-detects vault location. | P1 — MVP |
| 8 | **Smart Retention** | Tiered retention: all (24h), daily (7d), weekly (30d), delete older. Hard cap of 50 files with rollover. | P1 — MVP |
| 9 | **Claude Code Skill** | Packaged as installable skill for easy distribution. Auto-schedules background agent on session start. | P1 — MVP |
| 10 | **Cursor Support** | `.cursorrules` template for manual checkpointing. Same checkpoint format as Claude Code. | P1 — MVP |
| 11 | **Local-to-Obsidian Migration** | `migrate --to obsidian` command moves existing checkpoints to Obsidian vault and updates symlink. | P2 |
| 12 | **Cross-Editor Continuity** | Checkpoints from Claude Code readable in Cursor and vice versa via shared `.checkpoints/` folder. | P1 — MVP |
| 13 | **Team Sharing** | Checkpoint folder can be pointed to shared storage (Git repo, cloud folder). | P2 |
| 14 | **Configurable Retention** | Users override retention policy via skill config (max files, per-tier rules). | P2 |
| 15 | **Additional AI Editors** | Community-contributed support for Windsurf, Copilot, etc. | Future |
| 16 | **Web Dashboard** | View checkpoints across projects in a browser. | Future |
| 17 | **Git Auto-Commit** | Optionally auto-commit checkpoint files to a dedicated branch. | Future |

## 7. Success Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| **Setup Time** | Time from `curl` to first checkpoint | < 60 seconds |
| **Context Recovery Time** | Time from new session start to productive work | < 30 seconds (vs. 15-30 min without) |
| **Checkpoint Frequency** | Sessions with at least one auto-checkpoint | > 95% of sessions |
| **Zero-Interruption Rate** | Sessions where developer never notices the agent | 100% |
| **Cross-Editor Adoption** | Users who use checkpoints across multiple AI editors | Track % |
| **Session Continuity Score** | % of sessions that start with context (vs. cold start) | > 80% |
| **Time Saved per Developer** | Estimated time saved from avoiding context re-explanation | 2-5 hours/week |
| **GitHub Stars** | Open source adoption signal | Growth trend |
| **Weekly Active Users** | npm download count / install.sh usage | Growth trend |

### Business Value

| Benefit | Impact |
|---------|--------|
| **Developer productivity** | 2-5 hours/week saved per developer from eliminated context re-explanation |
| **Reduced frustration** | No more "start from scratch" after session crashes |
| **Better decisions** | Decision history preserved — no repeated debates |
| **Team alignment** | Session files serve as lightweight work logs |
| **Tool flexibility** | Developers choose their preferred AI editor without context penalty |

### Ease of Deployment and Operations

| Aspect | Design Choice |
|--------|---------------|
| **Install** | Single command (`curl` or `npx`). No package managers, no Docker, no servers. |
| **Dependencies** | Zero. Just bash + the AI editor. No Node.js required for shell script install. |
| **Maintenance** | Zero. Checkpoint files are plain markdown — no database, no config drift. |
| **Uninstall** | Delete the `.checkpoints` symlink and remove 2 lines from CLAUDE.md. Done. |
| **Upgrade** | Re-run `curl` install or `npx init`. Idempotent — never overwrites existing checkpoints. |
| **Storage cost** | ~5 KB per checkpoint. 50 files (hard cap) = 250 KB max. Negligible. |
| **Security** | All data stays local (or in your own cloud storage). Nothing leaves your machine. |

## 8. Repository Structure

```
ai-session-checkpoint/
├── README.md                           # Quick start + full docs
├── LICENSE                             # MIT
├── package.json                        # npm package for npx support
├── install.sh                          # Shell installer (zero dependencies)
├── bin/
│   └── init.js                        # CLI entry point (Node.js)
├── editors/
│   ├── claude-code/
│   │   ├── SKILL.md                    # Claude Code skill definition
│   │   └── example-CLAUDE.md           # Drop-in CLAUDE.md
│   └── cursor/
│       └── example-cursorrules         # Drop-in .cursorrules
├── scripts/
│   └── link-vault.sh                   # Symlink helper
├── templates/
│   ├── project-state.md               # Starter template
│   ├── decisions.md                    # Starter template
│   ├── problems.md                    # Starter template
│   └── sessions/.gitkeep              # Empty sessions dir
└── docs/
    └── PRD.md                         # This document
```

## 9. Appendix: FAQs

**Q: Do I need Obsidian to use this?**
No. The tool writes plain markdown files to any folder you choose — a simple `~/.ai-checkpoints/` folder works perfectly. However, if you use Obsidian, you can take advantage of snapshots when accessing from multiple machines — Obsidian syncs via Google Drive, iCloud, or Obsidian Sync, giving you cross-machine continuity plus search, graph view, and backlinks for free.

**Q: Does the auto-checkpoint interrupt my coding flow?**
No. The checkpoint runs as a background sub-agent in its own isolated space. Your main session sees nothing — no prompts, no output, no context pollution.

**Q: What if nothing changed since the last checkpoint?**
The agent checks `git diff` before each snapshot. If no files were created, modified, or deleted, it skips silently. Read-only work (searching code, reading docs, asking questions) produces zero checkpoints.

**Q: What AI editors are supported?**
Claude Code (with automatic background checkpointing) and Cursor (with manual checkpointing and `.cursorrules` integration). The checkpoint format is editor-agnostic, so any future AI editor that can read/write files will work.

**Q: How much storage do checkpoints use?**
Each checkpoint is ~5 KB of markdown. With the default hard cap of 50 files, maximum storage is ~250 KB per project. The tiered retention policy also automatically cleans up old checkpoints.

**Q: Can I share checkpoints across a team?**
Yes. Point the checkpoint folder to a shared location (Git repo, shared cloud folder, or shared Obsidian vault). Team members can read each other's session files.

**Q: Can I start with a local folder and switch to Obsidian later?**
Yes. Run `npx ai-session-checkpoint migrate --to obsidian`. It moves your existing checkpoint files into your Obsidian vault and updates the symlink. All history is preserved — nothing is lost.

**Q: How do I uninstall?**
Delete the `.checkpoints` symlink from your project and remove the checkpoint instructions from CLAUDE.md or .cursorrules. Your checkpoint files remain in the folder if you want to keep them.

**Q: Can I customize the checkpoint frequency?**
Yes. The default is 20 minutes, but you can change this in the skill configuration or CLAUDE.md instructions.

**Q: What happens if I hit the max checkpoint limit?**
The oldest session file is automatically deleted before writing the new one (classic rollover). The hard cap (default 50) ensures the folder never grows unbounded. The `project-state.md` file is never deleted — it always reflects current state.
