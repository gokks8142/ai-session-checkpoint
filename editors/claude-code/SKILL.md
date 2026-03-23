---
name: ai-session-checkpoint
description: Automatically save session context, decisions, and progress so no work is lost when sessions crash or context windows fill up.
triggers:
  - "checkpoint"
  - "save progress"
  - "save context"
  - "save session"
---

# ai-session-checkpoint

## On Session Start

Read `.checkpoints/project-state.md` and the latest file in `.checkpoints/sessions/` to pick up context from previous sessions. Briefly summarize what you found so the user knows you have context.

## On "checkpoint" / "save progress" / "save context"

1. **Check for changes**: Run `git diff --stat` to see if any files changed. If no changes and no significant decisions were made, tell the user "No changes to checkpoint" and skip.

2. **Write session file**: Create `.checkpoints/sessions/YYYY-MM-DD-HH-MM.md` with:
   ```
   # Session: YYYY-MM-DD HH:MM

   ## Summary
   - What was accomplished this session (2-5 bullet points)

   ## Files Changed
   - path/to/file.ts — what changed and why

   ## Decisions Made
   - Key decisions with brief rationale

   ## Open Items
   - What's left to do, blockers, next steps
   ```

3. **Update project state**: Rewrite `.checkpoints/project-state.md` with current reality:
   - What the project is
   - Tech stack
   - What's built and working
   - What's in progress
   - Key files and their purposes
   - Known issues

4. **Retention sweep**: Count files in `.checkpoints/sessions/`. If more than 50, delete the oldest file(s) to stay at 50.

5. **Confirm**: Tell the user what was saved with a brief summary.

## On Feature/Fix Completion

When you complete a significant feature or fix, proactively offer: "Want me to checkpoint this progress?"
