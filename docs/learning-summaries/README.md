# Learning summaries

This folder holds short end-of-session summaries for the mentors' Slack
channel. Generated `*.json` files are ignored because they contain personal
reflection. The learning log remains local and is never published wholesale.

## JSON contract

The agent writes exactly these five top-level fields:

```json
{
  "session": { "topic": "React state management" },
  "learned": ["Derived values do not always need component state"],
  "practiced": ["Refactored a component after writing the first version"],
  "difficulties": ["Still unsure when memoization is useful"],
  "support": {
    "needed": true,
    "question": "Could a senior developer review my memoization decision?"
  }
}
```

All five top-level fields must be present. `learned` needs at least one item;
`practiced` and `difficulties` may be empty arrays. `support.question` is
required only when support is needed.

All prose must come from the learner's confirmed reflection. Do not include
source code, diffs, repository contents, conversations, quiz answers,
credentials, or the full learning log. The publishing script reads only the
documented fields and validates the required types and Slack size limit before
sending.

Use filenames of the form `YYYY-MM-DD-topic-slug.json`; append `-2`, `-3`, and
so on rather than overwriting an existing summary.

## Preview and publish

From the host repository root, preview is the default and performs no network
request:

```bash
ruby learning-agent/scripts/publish_learning_summary.rb \
  learning-agent/docs/learning-summaries/2026-09-23-react-state.json
```

After the learner approves the exact preview:

```bash
ruby learning-agent/scripts/publish_learning_summary.rb \
  learning-agent/docs/learning-summaries/2026-09-23-react-state.json --send
```

The script derives the date locally and reads the learner name from
`LEARNER_NAME`. It reads `SLACK_LEARNING_WEBHOOK_URL` only in `--send` mode.
The optional `SLACK_MENTOR_HANDLE` is rendered only for a support request.
Webhook URLs must use `https://hooks.slack.com` or
`https://hooks.slack-gov.com`.
