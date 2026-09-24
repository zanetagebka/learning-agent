---
name: start-learning-project
description: Initialize or resume mentor-led learning in a software repository by creating private local context and log files, capturing the learner's goal and baseline, and selecting one small first task. Use for onboarding, starting a learning project, or resuming when usable local learning state is missing. Do not use for an ordinary task when Current Focus already exists.
---

# Start Learning Project

Set up the learning relationship without implementing application code.

## Locate and protect state

1. Locate both roots: the host repository root containing the project and the
   toolkit root containing this skill, normally `learning-agent/`. Read the
   host `AGENTS.md`, the toolkit `AGENTS.md`, and then the toolkit's
   `AGENTS.local.md` when it exists. All `docs/` paths below are relative to
   the toolkit root.
2. Inspect only the files needed to identify the stack, current repository
   state, and likely entry point. Do not read secrets or inventory the entire
   tree.
3. If either toolkit-local file is missing, copy its tracked template without
   overwriting anything:
   - `docs/PROJECT_CONTEXT.md` to `docs/PROJECT_CONTEXT.local.md`
   - `docs/LEARNING_LOG.md` to `docs/LEARNING_LOG.local.md`
4. When Git is available, verify the toolkit's `AGENTS.local.md`,
   `docs/*.local.md`, and `docs/learning-summaries/*.json` are ignored. If they
   are not ignored, stop before writing private answers and explain which
   ignore rule is missing.

If a local learning log already contains a usable `Current Focus`, summarize
the objective, open question, and evidence still needed. Ask whether it remains
the right focus. Resume it rather than rerunning onboarding unless the learner
asks to reset the plan. Never replace or silently archive their history.

## New-project interview

Ask no more than these three questions, one at a time, and wait after each:

1. What do you want to be able to build or explain by the end of this project?
2. Which relevant technologies or concepts can you already use without help,
   and which are new?
3. What small outcome would make the next 60–90 minute session worthwhile?

Keep the answers in the learner's words. The interview establishes intent; it
is not a quiz and does not justify claims about proficiency.

## Establish the first focus

Use the repository evidence and interview to propose one smallest useful task.
State:

- why it advances the learner's stated goal
- one primary concept to practise
- the first action the learner will take
- observable behavior and verification needed for completion
- one open question worth answering before implementation

Offer alternatives only when they would materially change the learning path.
Let the learner choose; do not make a consequential architecture choice on
their behalf.

Update `docs/PROJECT_CONTEXT.local.md` with the confirmed private context and
update only `Current Focus` in `docs/LEARNING_LOG.local.md`. Do not invent
experience, confidence, or verification. Do not edit application code.

Close by pointing to `mentor-coding` for the chosen task.
