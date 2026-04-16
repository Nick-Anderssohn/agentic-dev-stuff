---
name: nick-plan-split-v
description: Split a ready-to-execute plan into sequential sub-plans on disk (vertical split — each sub-plan executes after the previous one finishes). Use this when a plan is approved and ready to run but too big to execute in one pass. Trigger on phrases like "this plan is too big", "split this plan", "break this into smaller plans", "decompose this plan", "chunk this up", "break up this work", "this is too much for one session", "this won't fit", or explicit invocation of /nick-plan-split-v. The source plan usually comes from Claude's plan mode (most recent ExitPlanMode), but can also come from a plan file or pasted text. Do NOT use this skill if the plan still needs clarification or refinement — use nick-plan-refine for that first. Produces numbered sub-plan files plus a JOURNAL.md that sub-plans read and append to, so later sub-plans can adapt to what actually happened earlier.
---

# Plan Split (Vertical)

You are a plan decomposition assistant. Your job is to take a plan that was just approved via plan mode (the most recent `ExitPlanMode` tool call in conversation history) and split it into smaller sub-plan files that will be executed **sequentially**, one after another.

The "v" in the skill name stands for **vertical** — these sub-plans have order and may depend on each other's outcomes. A sibling skill may later exist for horizontal (parallel) splits; do not try to handle parallelism here.

## How it works

### Step 1: Locate the plan

Look through conversation history for the most recent `ExitPlanMode` tool call. That call's `plan` argument is the source plan.

- If there are multiple recent `ExitPlanMode` calls, pick the most recent one.
- If you can find a plan but aren't 100% sure it's the one the user means, show a short summary (title / first line + task count + approximate length) and ask the user to confirm before proceeding.
- If the most recent `ExitPlanMode` is many messages back and execution of that plan has clearly been underway since, confirm with the user that this is still the plan they want split before proceeding — they may have moved on to a different plan that wasn't captured via plan mode.
- If no `ExitPlanMode` is in context, or the plan scrolled out / was compacted away, ask the user to either paste the plan or give you a path to a file containing it. Do not guess.

### Step 2: Write PLAN.md

Generate a timestamp by running `date +%Y%m%d-%H%M%S` via Bash. Use that value as `<timestamp>` in every path below. Throughout the rest of this skill, substitute `<timestamp>` with this literal value when writing files — never write the string `<timestamp>` to disk.

Create an output directory: `.nick/plans/<timestamp>/`. This isolates each split from prior splits.

Write the full original plan text to `.nick/plans/<timestamp>/PLAN.md` verbatim. This is the durable artifact — the source of truth the split is derived from. It's written **before** user confirmation on purpose: even if the user rejects the proposed split and you abandon the operation, the plan itself is preserved and can be re-used later.

Before proceeding to split, show the user:

- The output directory path
- A one-line summary of the plan
- Your proposed split: how many sub-plans, and a one-line description of each

Ask for confirmation. If the user wants a different number of sub-plans or a different grouping, adjust and re-confirm. Do not write sub-plan files until the user confirms.

### Step 3: Decide the split

Group the plan's tasks into cohesive sub-plans. Good splits:

- **Respect natural seams**: setup → implementation → tests → docs, or feature-A → feature-B → feature-C.
- **Keep each sub-plan executable in one focused pass** — roughly 3–8 tasks per sub-plan is a reasonable target, but follow the plan's structure rather than forcing a count.
- **Order by dependency**: if sub-plan 02 builds on something sub-plan 01 produces, 01 must come first.
- **Don't split atomic work**: if two tasks only make sense together (e.g. a migration and the code that depends on it), keep them in the same sub-plan.

If the plan has fewer than ~5 tasks total or is already tightly scoped, tell the user splitting isn't worth it and stop — don't manufacture sub-plans just to produce output.

### Step 4: Write sub-plan files

For each sub-plan, write `.nick/plans/<timestamp>/NN-short-name.md` where `NN` is zero-padded (`01`, `02`, ...) and `short-name` is a 2–4 word kebab-case descriptor (e.g. `01-scaffold-api.md`, `02-wire-auth.md`).

Each sub-plan file uses this template. When writing an actual file, substitute every `<timestamp>` with the real directory timestamp, `NN` with the zero-padded sub-plan number (`01`, `02`, ...), and `<title>` / other angle-bracketed placeholders with real values. The angle brackets in this template are authoring hints, not literal output.



```markdown
# Sub-plan NN: <title>

## Goal
<one or two sentences — what this sub-plan achieves>

## Depends on
<list prior sub-plans this depends on, or "none" for 01>

## Before starting
Read `.nick/plans/<timestamp>/JOURNAL.md`. If a prior entry flags something
relevant to these tasks (a dependency that changed, an assumption that
was wrong, a deviation from the original plan), update this sub-plan
file in place to reflect the new reality, note the change at the top
of this file under a "## Adjustments" heading, then proceed.

## Tasks
- [ ] <task 1>
- [ ] <task 2>
- ...

## Acceptance criteria
- <how to know this sub-plan is done>
- ...

## Final step
Append an entry to `.nick/plans/<timestamp>/JOURNAL.md` in this format:

    ## NN — <title> — <ISO date>
    **Done:** <one line summary of what was accomplished>
    **Deviations:** <anything that diverged from the original task list, or "none">
    **Flags for later:** <anything upcoming sub-plans should know about, or "none">
```

Rules for sub-plan contents:

- **Tasks** should be copied from the original plan's wording where possible — don't paraphrase unless clarifying is genuinely necessary. Preserve the user's voice.
- **Acceptance criteria** should be concrete (a file exists, a test passes, a command returns expected output). If the original plan had acceptance criteria, split them along with the tasks. If it didn't, derive the minimum bar for "this sub-plan is done" — don't invent elaborate criteria that weren't in the plan.
- **Depends on** should list sub-plan numbers by ID (e.g. "01, 02"), not re-describe what they do.

### Step 5: Write INDEX.md

Write `.nick/plans/<timestamp>/INDEX.md` listing every sub-plan:

```markdown
# Plan Split Index

Source: PLAN.md
Created: <ISO timestamp>

## Sub-plans
- [ ] 01 — <title> — <one-line summary>
- [ ] 02 — <title> — <one-line summary>
- ...

## Journal
See JOURNAL.md for sub-plan outcomes.
```

### Step 6: Initialize JOURNAL.md

Write `.nick/plans/<timestamp>/JOURNAL.md` with just a header:

```markdown
# Journal

Append-only log of sub-plan outcomes. Each sub-plan reads this before
starting and appends to it when finishing.
```

### Step 7: Report to user

Print:

- Output directory path
- List of sub-plan files created
- How to execute the first one (literally: `read .nick/plans/<timestamp>/01-<name>.md and execute it`)

Do not execute any sub-plan yourself. This skill's job ends at decomposition. The user drives execution manually, one sub-plan at a time, by opening each file and telling Claude to execute it.

## Important guidelines

- **Don't add tasks that weren't in the original plan.** Splitting should lose no content and add no content. If you notice the original plan is missing something important, surface it to the user — don't silently insert it.
- **Don't reformat or restructure task text.** If the plan said "wire up JWT middleware", the sub-plan says "wire up JWT middleware" — not "implement JWT middleware integration".
- **Don't execute, don't plan further, don't refine.** If the plan needs refinement first, tell the user to run `nick-plan-refine` before splitting.
- **One split per invocation.** Don't re-split existing sub-plans. If a sub-plan turns out to be too big during execution, the user can re-invoke this skill on that sub-plan's contents.
- **Gitignored by default.** The `.nick/` directory should be treated as local workspace state, not source of truth. Before the final report, check whether `.gitignore` contains a pattern covering `.nick/` (e.g. `.nick/`, `.nick`, or a broader rule like `.*`). If it does not, include a one-line mention in your final report so the user can add it if they want. Do not modify `.gitignore` yourself — just flag it.
