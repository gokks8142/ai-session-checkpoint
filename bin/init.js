#!/usr/bin/env node

/**
 * ai-session-checkpoint CLI
 *
 * Usage:
 *   npx ai-session-checkpoint init          # Set up checkpoints for current project
 *   npx ai-session-checkpoint migrate --to obsidian  # Migrate local → Obsidian
 */

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");
const readline = require("readline");

const VERSION = "1.0.0";

// --- Helpers ---
function ask(question, defaultAnswer) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    const prompt = defaultAnswer ? `${question} (${defaultAnswer}): ` : `${question}: `;
    rl.question(prompt, (answer) => {
      rl.close();
      resolve(answer.trim() || defaultAnswer || "");
    });
  });
}

function green(t) { return `\x1b[32m${t}\x1b[0m`; }
function blue(t) { return `\x1b[34m${t}\x1b[0m`; }
function cyan(t) { return `\x1b[36m${t}\x1b[0m`; }
function bold(t) { return `\x1b[1m${t}\x1b[0m`; }
function dim(t) { return `\x1b[2m${t}\x1b[0m`; }

function writeIfMissing(filePath, content, label) {
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, content, "utf8");
    console.log(`  ${green("✓")} Created:     ${dim(label)}`);
    return true;
  }
  return false;
}

// No Obsidian-specific detection — user provides custom path if needed

// --- Templates ---
const TEMPLATES = {
  "project-state.md": `# Project State

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
`,
  "decisions.md": `# Architecture Decisions

<!-- Format:
## YYYY-MM-DD: Decision Title
**Context:** Why this decision was needed
**Decision:** What was decided
**Alternatives:** What else was considered
-->
`,
  "problems.md": `# Open Problems

<!-- Format:
## Problem Title
**Status:** open | investigating | blocked | resolved
**Description:** What's happening
**Impact:** Why it matters
**Notes:** Investigation progress
-->
`,
};

const CHECKPOINT_INSTRUCTIONS = `At session start, read \`.checkpoints/project-state.md\` and the latest file in \`.checkpoints/sessions/\` to pick up context from previous sessions.

When the user says "checkpoint" or when you complete a feature/fix, write a session summary to \`.checkpoints/sessions/\` (filename: \`YYYY-MM-DD-HH-MM.md\`) and update \`.checkpoints/project-state.md\`.`;

const SKILL_CONTENT = `---
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

Read \`.checkpoints/project-state.md\` and the latest file in \`.checkpoints/sessions/\` to pick up context from previous sessions. Briefly summarize what you found so the user knows you have context.

## On "checkpoint" / "save progress" / "save context"

1. **Check for changes**: Run \`git diff --stat\` to see if any files changed. If no changes and no significant decisions were made, tell the user "No changes to checkpoint" and skip.

2. **Write session file**: Create \`.checkpoints/sessions/YYYY-MM-DD-HH-MM.md\` with:
   \`\`\`
   # Session: YYYY-MM-DD HH:MM

   ## Summary
   - What was accomplished this session (2-5 bullet points)

   ## Files Changed
   - path/to/file.ts — what changed and why

   ## Decisions Made
   - Key decisions with brief rationale

   ## Open Items
   - What's left to do, blockers, next steps
   \`\`\`

3. **Update project state**: Rewrite \`.checkpoints/project-state.md\` with current reality:
   - What the project is
   - Tech stack
   - What's built and working
   - What's in progress
   - Key files and their purposes
   - Known issues

4. **Retention sweep**: Count files in \`.checkpoints/sessions/\`. If more than 50, delete the oldest file(s) to stay at 50.

5. **Confirm**: Tell the user what was saved with a brief summary.

## On Feature/Fix Completion

When you complete a significant feature or fix, proactively offer: "Want me to checkpoint this progress?"
`;

// --- Commands ---
async function init() {
  const projectDir = process.cwd();
  const projectName = path.basename(projectDir);
  const homedir = require("os").homedir();
  const defaultCheckpointDir = path.join(homedir, ".ai-checkpoints");

  console.log("");
  console.log(`${blue(bold("ai-session-checkpoint"))} ${dim(`v${VERSION}`)}`);
  console.log("");

  // Step 1: Storage
  let checkpointBase;
  console.log(cyan("? Where should checkpoints be stored?"));
  console.log(`  ${bold("1)")} Local folder ${dim(`(${defaultCheckpointDir}/)`)}`);
  console.log(`  ${bold("2)")} Custom path ${dim("(Google Drive, iCloud, Dropbox, etc.)")}`);
  const choice = await ask("  Choose [1/2]", "1");
  if (choice === "2") {
    const customPath = await ask("  Enter path", "");
    if (customPath) {
      const resolved = customPath.replace(/^~/, homedir);
      fs.mkdirSync(resolved, { recursive: true });
      checkpointBase = resolved;
    } else {
      checkpointBase = defaultCheckpointDir;
    }
  } else {
    checkpointBase = defaultCheckpointDir;
  }

  // Step 2: Project name
  const name = await ask(cyan("? Project name?"), projectName);
  const checkpointDir = path.join(checkpointBase, name);

  // Step 3: Detect editor
  let editorType = "claude-code";
  if (fs.existsSync(path.join(projectDir, ".cursorrules")) && !fs.existsSync(path.join(projectDir, "CLAUDE.md"))) {
    editorType = "cursor";
  }
  console.log(`${dim("  Editor detected: " + editorType)}`);
  console.log("");

  // Step 4: Create checkpoint folder + templates
  fs.mkdirSync(path.join(checkpointDir, "sessions"), { recursive: true });

  for (const [filename, content] of Object.entries(TEMPLATES)) {
    writeIfMissing(path.join(checkpointDir, filename), content, filename);
  }
  console.log(`  ${green("✓")} Templates:   ${dim("project-state.md, decisions.md, problems.md, sessions/")}`);

  // Step 5: Symlink
  const symlinkPath = path.join(projectDir, ".checkpoints");
  if (fs.existsSync(symlinkPath)) {
    const stat = fs.lstatSync(symlinkPath);
    if (stat.isSymbolicLink()) fs.unlinkSync(symlinkPath);
  }
  if (!fs.existsSync(symlinkPath)) {
    fs.symlinkSync(checkpointDir, symlinkPath);
    console.log(`  ${green("✓")} Symlink:     ${dim(`.checkpoints → ${checkpointDir}`)}`);
  }

  // Step 6: Editor config
  if (editorType === "claude-code" || editorType === "both") {
    const claudeMd = path.join(projectDir, "CLAUDE.md");
    if (fs.existsSync(claudeMd)) {
      const existing = fs.readFileSync(claudeMd, "utf8");
      if (!existing.includes(".checkpoints/project-state.md")) {
        fs.appendFileSync(claudeMd, "\n" + CHECKPOINT_INSTRUCTIONS + "\n");
        console.log(`  ${green("✓")} CLAUDE.md:   ${dim("Added checkpoint instructions")}`);
      }
    } else {
      fs.writeFileSync(claudeMd, CHECKPOINT_INSTRUCTIONS + "\n");
      console.log(`  ${green("✓")} CLAUDE.md:   ${dim("Created with checkpoint instructions")}`);
    }
  }

  if (editorType === "cursor" || editorType === "both") {
    const cursorrules = path.join(projectDir, ".cursorrules");
    if (fs.existsSync(cursorrules)) {
      const existing = fs.readFileSync(cursorrules, "utf8");
      if (!existing.includes(".checkpoints/project-state.md")) {
        fs.appendFileSync(cursorrules, "\n" + CHECKPOINT_INSTRUCTIONS + "\n");
        console.log(`  ${green("✓")} .cursorrules: ${dim("Added checkpoint instructions")}`);
      }
    } else {
      fs.writeFileSync(cursorrules, CHECKPOINT_INSTRUCTIONS + "\n");
      console.log(`  ${green("✓")} .cursorrules: ${dim("Created with checkpoint instructions")}`);
    }
  }

  // Step 7: Install skill
  if (editorType === "claude-code" || editorType === "both") {
    const skillDir = path.join(homedir, ".claude", "skills", "ai-session-checkpoint");
    fs.mkdirSync(skillDir, { recursive: true });
    fs.writeFileSync(path.join(skillDir, "SKILL.md"), SKILL_CONTENT);
    console.log(`  ${green("✓")} Skill:       ${dim("~/.claude/skills/ai-session-checkpoint/")}`);
  }

  // Step 8: .gitignore
  const gitignorePath = path.join(projectDir, ".gitignore");
  if (fs.existsSync(gitignorePath)) {
    const existing = fs.readFileSync(gitignorePath, "utf8");
    if (!existing.includes(".checkpoints")) {
      fs.appendFileSync(gitignorePath, "\n# ai-session-checkpoint\n.checkpoints\n");
      console.log(`  ${green("✓")} .gitignore:  ${dim("Added .checkpoints")}`);
    }
  }

  console.log("");
  console.log(`${green(bold("Done!"))} Checkpoints stored in: ${dim(checkpointDir)}`);
  console.log("");
}

async function migrate() {
  const args = process.argv.slice(3);
  if (args[0] !== "--to" || !args[1]) {
    console.log("Usage: ai-session-checkpoint migrate --to <path>");
    console.log("Example: ai-session-checkpoint migrate --to ~/Google\\ Drive/My\\ Drive/ClaudeCode");
    process.exit(1);
  }

  const projectDir = process.cwd();
  const symlinkPath = path.join(projectDir, ".checkpoints");
  const homedir = require("os").homedir();

  if (!fs.existsSync(symlinkPath)) {
    console.log("No .checkpoints found in current directory. Run 'init' first.");
    process.exit(1);
  }

  const currentTarget = fs.readlinkSync(symlinkPath);
  const newBase = args[1].replace(/^~/, homedir);
  const projectName = path.basename(projectDir);
  const newTarget = path.join(newBase, projectName);

  if (currentTarget === newTarget) {
    console.log("Already using that path. Nothing to migrate.");
    process.exit(0);
  }

  // Copy files
  fs.mkdirSync(newTarget, { recursive: true });
  execSync(`cp -r "${currentTarget}/"* "${newTarget}/"`, { stdio: "inherit" });

  // Update symlink
  fs.unlinkSync(symlinkPath);
  fs.symlinkSync(newTarget, symlinkPath);

  console.log(`${green("✓")} Migrated: ${dim(currentTarget)} → ${dim(newTarget)}`);
  console.log(`${green("✓")} Symlink updated`);
  console.log(`${green("✓")} All session history preserved`);
}

// --- Main ---
const command = process.argv[2] || "init";

switch (command) {
  case "init":
    init().catch(console.error);
    break;
  case "migrate":
    migrate().catch(console.error);
    break;
  default:
    console.log(`Unknown command: ${command}`);
    console.log("Usage: ai-session-checkpoint [init|migrate]");
    process.exit(1);
}
