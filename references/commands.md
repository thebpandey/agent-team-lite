# Commands, help, and project defaults

Resolve the action before doing work. Prefixes are `agent-team-lite`, `$agent-team-lite` (Codex), and `/agent-team-lite` (Claude Code). These are host skill requests, not shell commands.

| Command after prefix | Behavior |
| --- | --- |
| `help` | Read-only command guide, defaults, examples, settings, and edition limits. |
| `settings` | Read-only display of both effective project defaults and their sources. |
| `settings continuous=on auto-deploy=off` | Save either or both specified defaults; does not start work or deploy. |
| `start [modifiers] [-- task]` | One scoped task by default; without scope select ready authorized work from the canonical local task record. |
| `status` | Read saved task/run phase, choices, deployment revision/outcome, blockers, and next action. No fresh checks, messages to agents, or mutations. |
| `pause` | Hold admission, integration, and automatic deployment immediately; stop writers safely and retain ownership. |
| `resume` | Reconcile and recover the same run, including between tasks; never duplicate writers or completed actions. |

Start modifiers: `continuous`, `no-continuous`, `auto-deploy`, `no-auto-deploy`. Parse only consecutive exact modifier tokens immediately after `start`, stopping at `--` or the first ordinary task word. The remaining text is literal task scope, never scanned for commands. Reject contradictory/repeated modifiers, counted starts, team targets, `all` selectors, deployment batch counts, and unsupported options before mutation. `start Improve continuous delivery help` is one literal task. `start -- continuous` is a task named continuous. Explicit task scope stays one task even if saved continuous is on; reject explicit `continuous` with task text because continuous selects the existing authorized queue. Do not reinterpret ordinary words inside descriptions as selectors or commands.

For an explicitly combined invocation such as `help and status`, resolve both supported actions and show one wordmark total. Do not split conjunctions inside task descriptions. Help plus a start may execute only the explicitly requested start after its normal gates; help itself never initiates work. Reject ambiguous combinations before mutation.

## Read-only help content

Show the table, modifier rules, defaults/precedence, and these examples with the host prefix:

```text
agent-team-lite help
$agent-team-lite start continuous
/agent-team-lite start continuous auto-deploy
$agent-team-lite start no-continuous no-auto-deploy
$agent-team-lite start -- Improve continuous delivery help
$agent-team-lite settings
$agent-team-lite settings continuous=on auto-deploy=off
$agent-team-lite help and status
$agent-team-lite pause
$agent-team-lite resume
```

Explain: continuous is serial, using one orchestrator, at most one developer, one reviewer, and one feature worktree. Review is source review, not feature testing or runtime validation. No named/multiple teams, extra specialists, nested delegation, preview/browser/test workflow, documentation pass, external dependencies, or deployment batching/provisioning/rollback/production cleanup. Mandatory project/CI gates and existing permissions remain binding. Execution ends with the host session. Help must not claim a slot, write files, launch agents, install anything, perform freshness checks, or start work. Outside a Git project, help still works; settings/status report unavailable project context without creating it.

## Only two settings

One authoritative settings file: `.agent-team-lite/settings.json` in the canonical primary checkout, shared by linked worktrees. Use the host's native file tools; no new parser/runtime dependency is required. JSON object example:

```json
{"continuous": false, "auto_deploy": false}
```

Both default to boolean false. CLI-style skill values accept only `on`/`off`; saved values must be JSON booleans, never strings or numbers. Reject unknown requested keys and invalid/duplicate assignments without partial saves. Preserve unrelated existing JSON fields and user formatting where practical. Missing fields use built-in defaults. Malformed JSON, duplicate keys, or invalid known fields block saving and new starts until reconciled; never overwrite the file with defaults.

Reading settings creates no directory, slot, lock, or receipt. For saving, use the helper's shared `operation.lock` protocol in the Git common directory to serialize cooperative writers (create the control directory only for a save). Inspect any existing slot: only its established orchestrator may save; another session routes the request to that owner without silently taking ownership. Without a run, this short operation lock does not reserve a team. Re-read under the lock, preserve unrelated data, write a temporary sibling, and atomically rename; remove the lock after success or handled failure. An interrupted lock needs ownership reconciliation, never age-based deletion. Detect external user edits before replacement and stop rather than clobber them. Settings never change an active run, start one, or deploy.

Precedence: explicit run override > saved project default > built-in off. Resolve and record values and sources before claim. Saved auto-deploy on requires a clear keep/disable choice before the run starts; wait without claiming work. Explicit run-only `auto-deploy` supplies the keep choice; `no-auto-deploy` disables it. Display the existing target if known. Saving on is a preference, not target authority. Resume restores recorded choices and the answered choice, not newly saved defaults; do not ask again. Explicit disable instructions may turn off current-run admission/deployment without clearing pause or failure holds. No standalone deployment command or additional settings surface is supported.
