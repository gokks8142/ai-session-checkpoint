#!/usr/bin/env bash
#
# ai-session-checkpoint installer
# Zero dependencies — works on any Mac/Linux with bash
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/gokks8142/ai-session-checkpoint/main/install.sh | bash
#   OR
#   ./install.sh
#
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# --- Config ---
VERSION="1.0.0"
DEFAULT_CHECKPOINT_DIR="$HOME/.ai-checkpoints"
SKILL_DIR="$HOME/.claude/skills/ai-session-checkpoint"

# --- Detect project ---
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

echo ""
echo -e "${BLUE}${BOLD}ai-session-checkpoint${RESET} ${DIM}v${VERSION}${RESET}"
echo ""

# --- Step 1: Storage location ---
echo -e "${CYAN}? Where should checkpoints be stored?${RESET}"

# Try to detect Obsidian vault
OBSIDIAN_VAULT=""
for search_dir in \
  "$HOME/Library/CloudStorage"/*/*/ksomu*/Org/ClaudeCode \
  "$HOME/Library/CloudStorage"/GoogleDrive-*/My\ Drive/*/Org/ClaudeCode \
  "$HOME/Documents"/*/.obsidian/.. \
  "$HOME"/*/.obsidian/..
do
  if [ -d "$search_dir" ] 2>/dev/null; then
    OBSIDIAN_VAULT="$search_dir"
    break
  fi
done

STORAGE_CHOICE=""
if [ -n "$OBSIDIAN_VAULT" ]; then
  echo -e "  ${BOLD}1)${RESET} Local folder (${DIM}${DEFAULT_CHECKPOINT_DIR}/${RESET})"
  echo -e "  ${BOLD}2)${RESET} Obsidian vault (${DIM}auto-detected: ${OBSIDIAN_VAULT}${RESET})"
  echo ""
  read -p "  Choose [1/2] (default: 1): " STORAGE_CHOICE
else
  echo -e "  ${BOLD}1)${RESET} Local folder (${DIM}${DEFAULT_CHECKPOINT_DIR}/${RESET})"
  echo -e "  ${DIM}  (No Obsidian vault detected)${RESET}"
  echo ""
  STORAGE_CHOICE="1"
fi

STORAGE_CHOICE="${STORAGE_CHOICE:-1}"

if [ "$STORAGE_CHOICE" = "2" ] && [ -n "$OBSIDIAN_VAULT" ]; then
  CHECKPOINT_BASE="$OBSIDIAN_VAULT"
  STORAGE_LABEL="Obsidian vault"
else
  CHECKPOINT_BASE="$DEFAULT_CHECKPOINT_DIR"
  STORAGE_LABEL="Local folder"
fi

# --- Step 2: Project name ---
echo ""
echo -e "${CYAN}? Project name?${RESET} ${DIM}(${PROJECT_NAME})${RESET}"
read -p "  Name: " INPUT_NAME
PROJECT_NAME="${INPUT_NAME:-$PROJECT_NAME}"

CHECKPOINT_DIR="$CHECKPOINT_BASE/$PROJECT_NAME"

# --- Step 3: Detect AI editor ---
EDITOR_TYPE="unknown"
if [ -f "$PROJECT_DIR/CLAUDE.md" ] || command -v claude &>/dev/null; then
  EDITOR_TYPE="claude-code"
elif [ -f "$PROJECT_DIR/.cursorrules" ]; then
  EDITOR_TYPE="cursor"
fi

echo ""
if [ "$EDITOR_TYPE" = "claude-code" ]; then
  echo -e "${CYAN}? AI editor detected: ${BOLD}Claude Code${RESET}"
elif [ "$EDITOR_TYPE" = "cursor" ]; then
  echo -e "${CYAN}? AI editor detected: ${BOLD}Cursor${RESET}"
else
  echo -e "${CYAN}? AI editor:${RESET}"
  echo -e "  ${BOLD}1)${RESET} Claude Code"
  echo -e "  ${BOLD}2)${RESET} Cursor"
  echo -e "  ${BOLD}3)${RESET} Both"
  read -p "  Choose [1/2/3] (default: 1): " EDITOR_CHOICE
  case "${EDITOR_CHOICE:-1}" in
    2) EDITOR_TYPE="cursor" ;;
    3) EDITOR_TYPE="both" ;;
    *) EDITOR_TYPE="claude-code" ;;
  esac
fi

echo ""

# --- Step 4: Create checkpoint folder + templates ---
mkdir -p "$CHECKPOINT_DIR/sessions"

# project-state.md
if [ ! -f "$CHECKPOINT_DIR/project-state.md" ]; then
  cat > "$CHECKPOINT_DIR/project-state.md" << 'TMPL'
# Project State

## What is this project?
<!-- Brief description -->

## Tech Stack
<!-- Languages, frameworks, tools -->

## What's Built
<!-- Completed features and components -->

## In Progress
<!-- Current work items -->

## Key Files
<!-- Important files and their purposes -->

## Known Issues
<!-- Bugs, blockers, open questions -->
TMPL
  echo -e "  ${GREEN}✓${RESET} Created:     ${DIM}project-state.md${RESET}"
fi

# decisions.md
if [ ! -f "$CHECKPOINT_DIR/decisions.md" ]; then
  cat > "$CHECKPOINT_DIR/decisions.md" << 'TMPL'
# Architecture Decisions

<!-- Format:
## YYYY-MM-DD: Decision Title
**Context:** Why this decision was needed
**Decision:** What was decided
**Alternatives:** What else was considered
-->
TMPL
  echo -e "  ${GREEN}✓${RESET} Created:     ${DIM}decisions.md${RESET}"
fi

# problems.md
if [ ! -f "$CHECKPOINT_DIR/problems.md" ]; then
  cat > "$CHECKPOINT_DIR/problems.md" << 'TMPL'
# Open Problems

<!-- Format:
## Problem Title
**Status:** open | investigating | blocked | resolved
**Description:** What's happening
**Impact:** Why it matters
**Notes:** Investigation progress
-->
TMPL
  echo -e "  ${GREEN}✓${RESET} Created:     ${DIM}problems.md${RESET}"
fi

echo -e "  ${GREEN}✓${RESET} Templates:   ${DIM}project-state.md, decisions.md, problems.md, sessions/${RESET}"

# --- Step 5: Create symlink ---
SYMLINK_PATH="$PROJECT_DIR/.checkpoints"

if [ -L "$SYMLINK_PATH" ]; then
  rm "$SYMLINK_PATH"
elif [ -e "$SYMLINK_PATH" ]; then
  echo -e "  ${RED}!${RESET} .checkpoints already exists and is not a symlink. Skipping."
  echo ""
else
  true
fi

if [ ! -e "$SYMLINK_PATH" ]; then
  ln -s "$CHECKPOINT_DIR" "$SYMLINK_PATH"
  echo -e "  ${GREEN}✓${RESET} Symlink:     ${DIM}.checkpoints → ${CHECKPOINT_DIR}${RESET}"
fi

# --- Step 6: Configure AI editor ---
CHECKPOINT_INSTRUCTIONS='At session start, read `.checkpoints/project-state.md` and the latest file in `.checkpoints/sessions/` to pick up context from previous sessions.

When the user says "checkpoint" or when you complete a feature/fix, write a session summary to `.checkpoints/sessions/` (filename: `YYYY-MM-DD-HH-MM.md`) and update `.checkpoints/project-state.md`.'

# Claude Code: CLAUDE.md
if [ "$EDITOR_TYPE" = "claude-code" ] || [ "$EDITOR_TYPE" = "both" ]; then
  CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
  if [ -f "$CLAUDE_MD" ]; then
    # Check if instructions already exist
    if ! grep -q ".checkpoints/project-state.md" "$CLAUDE_MD" 2>/dev/null; then
      echo "" >> "$CLAUDE_MD"
      echo "$CHECKPOINT_INSTRUCTIONS" >> "$CLAUDE_MD"
      echo -e "  ${GREEN}✓${RESET} CLAUDE.md:   ${DIM}Added checkpoint instructions${RESET}"
    else
      echo -e "  ${DIM}  CLAUDE.md already has checkpoint instructions${RESET}"
    fi
  else
    echo "$CHECKPOINT_INSTRUCTIONS" > "$CLAUDE_MD"
    echo -e "  ${GREEN}✓${RESET} CLAUDE.md:   ${DIM}Created with checkpoint instructions${RESET}"
  fi
fi

# Cursor: .cursorrules
if [ "$EDITOR_TYPE" = "cursor" ] || [ "$EDITOR_TYPE" = "both" ]; then
  CURSORRULES="$PROJECT_DIR/.cursorrules"
  if [ -f "$CURSORRULES" ]; then
    if ! grep -q ".checkpoints/project-state.md" "$CURSORRULES" 2>/dev/null; then
      echo "" >> "$CURSORRULES"
      echo "$CHECKPOINT_INSTRUCTIONS" >> "$CURSORRULES"
      echo -e "  ${GREEN}✓${RESET} .cursorrules: ${DIM}Added checkpoint instructions${RESET}"
    else
      echo -e "  ${DIM}  .cursorrules already has checkpoint instructions${RESET}"
    fi
  else
    echo "$CHECKPOINT_INSTRUCTIONS" > "$CURSORRULES"
    echo -e "  ${GREEN}✓${RESET} .cursorrules: ${DIM}Created with checkpoint instructions${RESET}"
  fi
fi

# --- Step 7: Install Claude Code skill (if applicable) ---
if [ "$EDITOR_TYPE" = "claude-code" ] || [ "$EDITOR_TYPE" = "both" ]; then
  mkdir -p "$SKILL_DIR"

  cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
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
SKILLEOF

  echo -e "  ${GREEN}✓${RESET} Skill:       ${DIM}Installed to ~/.claude/skills/ai-session-checkpoint/${RESET}"
fi

# --- Step 8: Add .checkpoints to .gitignore ---
GITIGNORE="$PROJECT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".checkpoints" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# ai-session-checkpoint" >> "$GITIGNORE"
    echo ".checkpoints" >> "$GITIGNORE"
    echo -e "  ${GREEN}✓${RESET} .gitignore:  ${DIM}Added .checkpoints${RESET}"
  fi
else
  echo "# ai-session-checkpoint" > "$GITIGNORE"
  echo ".checkpoints" >> "$GITIGNORE"
  echo -e "  ${GREEN}✓${RESET} .gitignore:  ${DIM}Created with .checkpoints${RESET}"
fi

# --- Done ---
echo ""
echo -e "${GREEN}${BOLD}Done!${RESET} Checkpoints stored in: ${DIM}${CHECKPOINT_DIR}${RESET}"
echo ""
if [ "$EDITOR_TYPE" = "claude-code" ] || [ "$EDITOR_TYPE" = "both" ]; then
  echo -e "  Your next Claude Code session will:"
  echo -e "  ${DIM}  1. Read .checkpoints/ on start for context${RESET}"
  echo -e "  ${DIM}  2. Checkpoint on \"checkpoint\" command${RESET}"
  echo -e "  ${DIM}  3. Offer to checkpoint when features are done${RESET}"
fi
echo ""
