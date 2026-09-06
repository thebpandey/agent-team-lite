# Agent Team Lite

One team. One feature worktree. One orchestrator who also integrates the result.

Agent Team Lite is a standalone development skill for Codex and Claude Code. It provides a small development and source-review workflow without external skill or plugin dependencies.

## Version

Current version: **6.1.0**. `metadata.version` in `SKILL.md` is authoritative; see [CHANGELOG.md](CHANGELOG.md). This is Lite's first recorded semantic version, set to 6.1.0 at the maintainer's explicit request; earlier commits were unversioned. It does not imply feature parity with the full edition. Update metadata, README, and changelog together: PATCH for fixes, MINOR for compatible additions, MAJOR for incompatible changes. Displaying the installed version is local and performs no remote freshness check.

## Architecture

| Part | Responsibility |
| --- | --- |
| Orchestrator and integrator | Plan the task, own progress notes, dispatch the developer/reviewer, and integrate the reviewed result. |
| One developer | Implement and repair the requested feature. |
| One reviewer | Read stable source and report concrete issues. |
| Main checkout | Planning, shared task/resume records, and the integrated result. |
| One feature worktree | All feature changes, source review, and conflict repairs. |

A worktree is a separate working folder managed by Git. Lite creates only one additional worktree per unfinished task. There are no child worktrees, dedicated integration worktrees, or additional team leads.

Only the orchestrator starts teammates. The developer and reviewer never spawn agents. Review and repair reuse the same team; developer writes stop while the reviewer inspects the source.

## Supported commands

These are requests to the skill, not shell commands.

| Codex | Claude Code | Result |
| --- | --- | --- |
| `$agent-team-lite start [task]` | `/agent-team-lite start [task]` | Start one scoped task. Without a task description, select one ready unassigned task from an existing local task record. |
| `$agent-team-lite status` | `/agent-team-lite status` | Read the current team's saved progress and blockers without interrupting work. |
| `$agent-team-lite pause` | `/agent-team-lite pause` | Safely pause the only team, preserving its slot and worktree. |
| `$agent-team-lite resume` | `/agent-team-lite resume` | Continue the same unfinished team, task, and worktree. |

Help and settings are also supported:

| Command (use `$agent-team-lite`, `/agent-team-lite`, or `agent-team-lite`) | Result |
| --- | --- |
| `help` | Read-only guide to every command, defaults, examples, and edition limits. |
| `settings` | Read project defaults without writing files. |
| `settings continuous=on auto-deploy=off` | Save either or both defaults for future runs only. |
| `start continuous` | Process ready authorized tasks from the existing local task record serially. |
| `start continuous auto-deploy` | Same serial run, deploying each completed integrated task through the existing authorized mechanism. |
| `start no-continuous no-auto-deploy` | Override saved defaults for one run. |

Both settings default to off, in the primary checkout's `.agent-team-lite/settings.json`. Explicit run override > saved project default > built-in default. Saved auto-deploy on requires a keep/disable choice before starting; explicit run-only `auto-deploy` supplies that choice. Saving settings does not start or deploy. Resume restores recorded run choices. No unknown destination or mandatory gate is authorized by enabling deployment.

Modifiers are recognized only immediately after start; `--` begins literal task text. A literal task remains one scoped task. See [complete routing/settings rules](references/commands.md) and [serial recovery/deployment rules](references/runs.md). `agent-team-lite start Improve continuous delivery` does not enable continuous mode.

Every Lite message uses the exact 74-character equals-sign borders, blank lines, and Lite role labels. User-invoked help/start/resume/settings/status show the Unicode solid wordmark with lowercase lite, installed version, creator attribution, and Lite source once, including combined commands. Internal iterations do not repeat it; native tool payloads remain unchanged. See [output](references/output.md).

For example:

```text
$agent-team-lite start Add an email preference setting
$agent-team-lite status
$agent-team-lite pause
$agent-team-lite resume
```

`start` does not resume or replace an unfinished team. A new task is refused while the slot is active, paused, interrupted, awaiting integration, or awaiting worktree removal:

> Agent Team Lite already has an unfinished team in this repository. Resume or complete that team before starting another.

There is no team picker, named-team targeting, `all`, `with-preview`, `approve`, dependency setup, or force-start command. Plain-language equivalents follow the same limits.

## Included

- One orchestrator, one developer, and one source reviewer.
- A local task record, short resume notes, and final requirement reconciliation.
- A focused source-review and repair loop.
- Basic UI guidance using the project's existing components and conventions.
- A persistent single-team reservation shared across the repository's linked worktrees.
- Integration by the orchestrator and safe removal of the one completed feature worktree.
- Optional serialized continuous scheduling and limited per-task auto-deploy, both off by default.
- Deployment failure holds both further admission and deployment until recovery is resolved.

By default, the orchestrator keeps `.agent-team-lite/TASKS.md` and `.agent-team-lite/CONTEXT.md` in the main checkout. An existing suitable local task record can be reused instead of creating a duplicate ledger. The helper keeps team reservation metadata in Git's shared metadata directory.

## Excluded

- Multiple teams, nested delegation, specialist agents, or a separate integrator.
- Agents or workflow stages for writing feature-code documentation.
- Feature, unit, integration, end-to-end, or automated browser testing.
- Visual browser review, preview servers, and preview-approval gates.
- Shared mistake databases and cross-team handoff systems.
- External skill/plugin dependencies and dependency installation workflows.
- Deployment batching, provisioning, rollback automation, production testing, or production cleanup.

Task and resume notes are part of coordination, not feature-code documentation. Source review does not prove that a feature works at runtime. An already available build, lint, or type check may be used when materially needed, but it must not disguise a test suite. Mandatory project or CI gates remain in force; Lite reports a conflict or blocked gate instead of disabling it or claiming it passed.

## Installation

Download the installable `agent-team-lite-6.1.0.zip` from [GitHub Releases](https://github.com/thebpandey/agent-team-lite/releases/tag/v6.1.0), then follow [Installation Instructions](Installation%20Instructions.md). Install the complete folder, including `scripts/` and `references/`, using your host's supported skill installation process. Do not install only `SKILL.md`. The installation ZIP omits repository-only maintenance checks.

The authorized distribution repository is [thebpandey/agent-team-lite](https://github.com/thebpandey/agent-team-lite). A manual user-wide installation on a Unix-like system can use these locations:

**Codex:**

```sh
mkdir -p ~/.agents/skills
git clone https://github.com/thebpandey/agent-team-lite.git ~/.agents/skills/agent-team-lite
```

**Claude Code:**

```sh
mkdir -p ~/.claude/skills
git clone https://github.com/thebpandey/agent-team-lite.git ~/.claude/skills/agent-team-lite
```

If the destination already exists, inspect it and update the existing installation. Do not overwrite user changes. ChatGPT-managed installation is separate from installation on your own computer.

The workflow needs Git, a standard shell, ordinary system utilities, and a host that can dispatch the developer and reviewer in the specified worktree. It adds no package or plugin dependencies. Model selection follows the user's existing host policy and available coding-capable models; Lite does not buy access or change its parent model. Native dispatch must be verified on the actual host.

## Single-team guarantee and limits

The bundled shell helper reserves one slot atomically before work starts. Pausing keeps that reservation. A second cooperative Lite start is denied, including from another linked worktree. Interrupted or incomplete metadata is treated as occupied until ownership is reconciled.

The slot is released only after integration is recorded, team activity is stopped, the feature worktree is safely removed, and the run ends safely. Continuous runs retain the same reservation between tasks; enabled per-task deployment completes before the next admission. A reviewed feature waiting for a merge still occupies the slot. Lite never force-removes unfinished files to make room for another task.

This reservation coordinates invocations that follow the skill within one Git repository. It is not an operating-system security boundary and does not control unrelated tools, independent clones, or other machines. Use one designated checkout for a project. Known active or paused full Agent-Team work in that repository also blocks a Lite start.

A skill cannot guarantee a checkpoint after a crash or keep agents running after its host closes. Resume inspects actual files and surviving writers before continuing. Missing work or uncertain ownership is reported rather than silently replaced.

## Package layout

| File | Purpose |
| --- | --- |
| `SKILL.md` | Scope, commands, roles, and workflow. |
| `agents/openai.yaml` | Codex/ChatGPT display metadata. |
| `scripts/team-slot.sh` | Cooperative single-team reservation and phase checks. |
| `references/state.md` | Ownership, internal helper usage, and recovery rules. |
| `references/hosts.md` | Native Codex and Claude Code dispatch constraints. |
| `references/commands.md` | Help, routing, and two project settings. |
| `references/output.md` | Wordmark, installed version, attribution, and message borders. |
| `references/runs.md` | Serial task transitions, deployment, pause, and recovery. |
| `CHANGELOG.md` | Semantic release history. |
| `checks/slot.sh` | Isolated package-maintenance checks; never a feature workflow stage. |
| `references/integration.md` | Integration and safe worktree removal by the orchestrator. |

The shell helper is an internal component, not an expanded user command set. Permissions, source-review quality, teammate liveness, and required project gates also depend on the orchestrator and host.

## License

Agent Team Lite is free to use under the [Agent Team Lite Proprietary Free-Use License](LICENSE). No paid LearnStack OS subscription is required. It is proprietary software with publicly visible source, not an open-source project.

You may install and use the unmodified skill, let coding agents process it for your tasks, and create and sell your own resulting applications. Modification, repackaging, redistribution, sublicensing, and resale of the skill require written permission, except rights independently granted by applicable law or GitHub's terms. GitHub viewing and forking rights remain intact. The license does not claim ownership of unprotected ideas or independently created functionality.

See LICENSE for the complete terms. For permission requests, contact support@learnstackos.com.
