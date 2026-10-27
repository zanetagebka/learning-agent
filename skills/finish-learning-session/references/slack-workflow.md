# Slack summary workflow

The agent prepares data; the local script performs the network action. Never
read the webhook URL or print environment variables.

Paths beginning with `docs/` are relative to the toolkit root, normally
`learning-agent/`.

## Build the summary

Use the five-field contract in `docs/learning-summaries/README.md`. Every value
must be supported by learner-confirmed reflection. Repository metadata is
deliberately absent from the Slack payload; the script adds only the current
date and the configured learner name.

Write the file as valid JSON using this exact shape:

```json
{
  "session": {
    "topic": "Short session topic"
  },
  "learned": [
    "One learner-confirmed insight"
  ],
  "practiced": [],
  "difficulties": [],
  "support": {
    "needed": false
  }
}
```

Follow these syntax rules strictly:

- Include all five top-level fields shown above.
- Use double quotes around every key and string.
- Use lowercase JSON booleans `true` and `false`, never quoted booleans.
- Keep `learned`, `practiced`, and `difficulties` as arrays of strings; use
  `[]` when there are no items.
- If the learner has no confirmed insight, use `"learned": []`, including
  when requesting help with a blocked session. Never invent learning progress.
- When `support.needed` is `true`, add a non-blank `support.question` string.
- Do not add comments, Markdown fences, trailing commas, or repository data to
  the JSON file.

Never include conversations, the cold-check question or answer, code, diffs,
file contents, credentials, or the full learning log.

Create `docs/learning-summaries/YYYY-MM-DD-topic-slug.json`. If that path
exists, append `-2`, `-3`, and so on. Do not overwrite an earlier summary and
do not stage the new file.

When support is needed, make `support.question` actionable: name the decision
or blocker and include the most useful attempted approach in the question when
needed for context. Do not fabricate an attempt.

## Preview

Run from the host repository root:

```bash
ruby learning-agent/scripts/publish_learning_summary.rb <summary-path>
```

No flag means dry run. Show the complete output to the learner and ask whether
to send that exact payload. A request earlier in the conversation to "share a
summary" is not approval after preview; wait for a clear yes.

If validation fails, correct only the JSON problem using confirmed information,
then preview again. Never weaken validation to make a payload publish.

## Send

Only after approval, run:

```bash
ruby learning-agent/scripts/publish_learning_summary.rb <summary-path> --send
```

Report success or the sanitized failure. Do not retry automatically. Confirm
with `git status` or `git check-ignore` that the summary remains ignored and
unstaged.
