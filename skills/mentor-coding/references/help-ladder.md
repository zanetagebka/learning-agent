# Help ladder

Use the lowest level that satisfies the learner's request. Do not move upward
merely because a faster answer is available.

## Level 1 — Questions and framing

Clarify the behavior, inputs, outputs, constraints, and existing assumptions.
Ask the learner to sketch the data flow or responsibility split. Do not provide
the solution inside a leading question.

## Level 2 — Conceptual hints

Explain the missing concept and give two or three directional hints. Use a
small analogy or diagram only when it makes the relationship clearer. Keep the
project-specific implementation unstated.

## Level 3 — Debugging path

Translate the symptom into competing hypotheses. Suggest the smallest
observations that distinguish them, in order. Ask for the resulting values or
errors before prescribing the fix.

If the learner has already supplied evidence that isolates the cause, explain
the cause directly; do not make them repeat a ritual.

## Level 4 — Pseudocode or isolated example

Show control flow, interfaces, or a tiny unrelated example. Do not paste a
drop-in implementation for the learner's file. Ask the learner to translate it
into the project and return with their attempt.

## Level 5 — Scoped implementation

Use only after an explicit request to write or implement code for a named step.
Permission is local to that step and ends when it is complete.

- state the intended diff first
- preserve existing architecture unless a change was chosen explicitly
- edit the fewest relevant files
- include or update focused tests when appropriate
- explain the important lines and alternatives afterward
- ask the learner to explain one decision back in their own words

If the learner requests an entire feature, split it into reviewable steps and
ask which step they want implemented first unless the steps are inseparable.

## Review shape

Review rather than rewrite. Cover only categories relevant to the submitted
code:

```markdown
## Review

### Works well
- ...

### Should improve
- [severity] `path:line` — consequence and reasoning

### Questions for you
- ...

### Suggested next refactor
- ...
```

Prioritize correctness and contracts, then data flow, error handling, tests,
readability, naming, and maintainability. Avoid style comments that do not
change understanding or behavior.

## Evidence shape

Prefer concrete evidence notes:

```text
Command/check: ...
Working directory: ...
Result: exit 0 / observed behavior / not run
Proves: ...
Does not prove: ...
```

Never upgrade `not run`, assumed output, or an agent-generated explanation into
evidence.
