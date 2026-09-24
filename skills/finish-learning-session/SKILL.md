---
name: finish-learning-session
description: Close a software-learning session by separating repository evidence from learner reflection, asking a cold understanding check, updating the private learning log, and optionally preparing an approval-gated Slack escalation. Use when the learner says the session is finished, asks to update the learning log, or wants help from a mentor or team member.
---

# Finish Learning Session

Close the session without adding application features or inventing learning
claims.

## Inspect evidence first

Treat paths beginning with `docs/` as relative to the toolkit root, normally
`learning-agent/`, and project paths as relative to the host repository root.
Read:

- Git status and the relevant diff, including nested repositories when the
  project actually uses them
- `Current Focus` and the latest entry in `docs/LEARNING_LOG.local.md`
- relevant test or manual-check output available in the session

If the local log is missing, create it from `docs/LEARNING_LOG.md` without
overwriting another file. Do not read secrets or unrelated private files.

Summarize repository facts separately from missing evidence. Never claim that a
change works when verification did not run or failed.

## Collect learner-owned reflection

Ask only for subjective information that cannot be inferred. At minimum obtain:

1. What was most difficult or surprising?
2. What can the learner now explain without help, in their own words?

Ask one concise prompt and wait. Preserve the meaning of the response instead
of polishing it into stronger confidence than the learner expressed.

Then ask one open, interview-style question grounded in an actual decision,
invariant, or data flow from this session. Ask a second only when it checks a
different important concept. Give no hint, options, or leading completion, and
stop for the answer. Do not publish the question or answer.

If an answer exposes a gap, ask whether the learner wants it recorded under
`difficulties` or as a human-support request. Do not immediately teach or
correct the answer during the check.

## Decide on human support

Ask explicitly whether help from a senior developer or another team member is
needed. The learner owns the decision. A useful support request states one
specific question and briefly says what has already been tried. Recommend
escalation when repeated attempts failed or a blocker remains, but never mark
support as needed by assumption.

## Update the private log

Append one session entry to `docs/LEARNING_LOG.local.md` using its existing
structure. Record:

- objective and observed repository facts
- exact verification evidence or `Not run`
- learner-provided reflection and highest help level used
- unresolved questions and support decision
- exactly one primary next step, with reason, first learner action, concepts,
  and definition of done

Update `Current Focus` to match that handoff and add demonstrated gaps to the
Review Queue. Do not write personal reflection to the tracked template. When
Git is available, confirm the local file is ignored and not staged.

## Optional Slack handoff

If the learner wants a Slack summary or human support, read
[references/slack-workflow.md](references/slack-workflow.md) and follow it.
Preparing a preview is allowed after reflection is confirmed. Sending always
requires separate, explicit approval of the exact preview.

Close with the evidence recorded, the one next step, and whether the Slack
summary was not requested, previewed, or sent.
