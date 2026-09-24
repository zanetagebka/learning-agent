# Learning Agent

Learning Agent turns a software repository into a mentor-led learning space. The
agent may explain, question, review, and debug, but it does not take over the
learner's implementation unless the learner explicitly asks for code for a
small, named step.

The bundle combines two useful ideas:

- repository-wide guardrails in `AGENTS.md`
- focused, portable workflows in `skills/`

Progress remains durable in a private local learning log. At the end of a
session, a privacy-limited summary can be previewed and, after explicit
confirmation, sent to a mentors' Slack channel by a local script.

## Add it to a repository

Keep the whole toolkit in a `learning-agent/` directory inside the repository
you want to learn in:

```text
repository-x/
├── AGENTS.md                 # small bootstrap created by the installer
├── learning-agent/           # this complete toolkit
├── project-a/
└── project-b/
```

From `repository-x/`, run:

```bash
ruby learning-agent/scripts/install.rb
```

The installer creates `AGENTS.md` when it is missing or appends one marked
Learning Agent section when it already exists. It never replaces existing
repository instructions, and rerunning it is safe. All other toolkit files,
including local learning state and the Slack publisher, stay under
`learning-agent/`.

One installation can cover several project folders when `repository-x/` is a
single Git repository. If those folders are separate Git repositories, put and
install a toolkit in each one so instructions and learning state remain scoped
correctly.

The root bootstrap routes relevant requests to the portable skills, so the
bundle works with agents that read repository instructions. A skill-capable
host can optionally register `learning-agent/skills/` using its normal
project-skill mechanism. For example, Codex project skills use
`.agents/skills/<skill-name>/SKILL.md`; copying the three skill directories
there enables native discovery but is not required for routing through
`AGENTS.md`.

Start a new project with:

```text
Use start-learning-project to set up this repository for mentored learning.
```

For normal work:

```text
Use mentor-coding to help me work through this task without taking it over.
```

At the end:

```text
Use finish-learning-session to close the session and update my learning log.
```

## Shared versus local state

| Shared in the repository | Private on the developer's machine |
|---|---|
| `learning-agent/AGENTS.md` | `learning-agent/AGENTS.local.md` |
| `learning-agent/docs/PROJECT_CONTEXT.md` | `learning-agent/docs/PROJECT_CONTEXT.local.md` |
| `learning-agent/docs/LEARNING_LOG.md` | `learning-agent/docs/LEARNING_LOG.local.md` |
| skills and publishing scripts | `learning-agent/docs/learning-summaries/*.json` |

Shared files define behavior and reusable structure. Local files contain the
active project's private context, personal reflection, knowledge gaps, and
Slack-ready summaries. The supplied `.gitignore` keeps local state out of Git.

`start-learning-project` creates missing local files from the tracked templates
without overwriting existing notes.

## How mentoring works

The help level increases only when the learner asks:

1. Questions and task framing
2. Conceptual hints
3. A debugging path
4. Pseudocode or an isolated example
5. A minimal implementation for the explicitly requested step

An implementation request is scoped to that step. It is not permanent
permission for the agent to complete the feature or make architecture choices.

Sessions begin with retrieval from earlier work and end with evidence. Passing
code is recorded separately from the learner's own explanation; neither is
treated as proof of the other.

## Slack escalation

The agent never connects to Slack and never reads a webhook. It writes a small,
ignored JSON summary, then invokes the local publisher. Running the publisher
without `--send` is always a dry run:

```bash
ruby learning-agent/scripts/publish_learning_summary.rb \
  learning-agent/docs/learning-summaries/2026-09-23-topic.json
```

After the learner approves that exact payload, publish explicitly:

```bash
ruby learning-agent/scripts/publish_learning_summary.rb \
  learning-agent/docs/learning-summaries/2026-09-23-topic.json --send
```

Publishing requires `SLACK_LEARNING_WEBHOOK_URL` and `LEARNER_NAME`.
`SLACK_MENTOR_HANDLE` is optional (for example `<@U123>`). These values stay in
the shell environment and must never be placed in a prompt, JSON file, or
repository file. For safety, the publisher accepts only official
`hooks.slack.com` and `hooks.slack-gov.com` webhook hosts.

Run the script tests with:

```bash
ruby learning-agent/test/publish_learning_summary_test.rb
ruby learning-agent/test/install_test.rb
```

## Design sources

This toolkit extracts the learning-first workflow from the local
`code_reviewer` project and strengthens it with patterns from the MIT-licensed
[AI Engineering from Scratch learning skills](https://github.com/rohitg00/ai-engineering-from-scratch/tree/main/skills): focused skills, persistent state, retrieval practice, one learning unit at a time, and evidence-based completion.
