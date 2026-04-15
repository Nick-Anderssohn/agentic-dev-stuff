# agentic-dev

Personal collection of [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills), with a script to install them globally.

## Layout

```
skills/
  nick-<skill-name>/
    SKILL.md          # required — frontmatter (name, description) + instructions
    ...               # optional scripts, references, templates
install.sh
```

All skills in this repo are prefixed with `nick-` to distinguish them from third-party skills under `~/.claude/skills/`.

## Install

```sh
./install.sh                  # symlink every skill in ./skills/ into ~/.claude/skills/
./install.sh nick-plan-refine # install only the named skills
./install.sh --copy           # copy files instead of symlinking
```

Symlinks are the default so edits in this repo are live immediately. Re-run the script after adding a new skill. Existing entries at the destination are replaced.

## Adding a skill

1. Create `skills/nick-<name>/SKILL.md` with the required frontmatter:
   ```markdown
   ---
   name: nick-<name>
   description: One-line description used to decide when the skill applies.
   ---

   Instructions for Claude go here.
   ```
2. Add any supporting files (scripts, references) alongside `SKILL.md`.
3. Run `./install.sh` to install.

## Skills

- **nick-plan-refine** — iteratively refine a saved plan by surfacing gray areas, asking targeted clarifying questions, and updating the plan file in place.
