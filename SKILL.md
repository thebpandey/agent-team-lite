---
name: agent-team-lite
description: Develop one scoped task at a time on Codex or Claude Code with one orchestrator, one developer, one reviewer, local task notes, and exactly one feature worktree. Use for agent-team-lite start, status, pause, resume, or implementation explicitly assigned to Lite. Excludes multi-team coordination, preview approval, feature testing, documentation agents, external skill dependencies, and deployment automation.
---

# Agent Team Lite

Use one team per Git repository, including all linked worktrees and sessions that use this skill. The orchestrator also performs integration. Use main for planning and shared records; create exactly one additional worktree for feature development. A worktree is a separate working folder managed by Git. Do not create an integration worktree or child worktrees.

Keep this package independent. Use only the host's native agent/file/process tools, Git, a standard shell, and the project's already available build tools when required. Do not load, reference, install, require, or invoke other skills, plugins, package collections, or design-tool dependencies as part of Lite. Do not load the full Agent-Team package to fill gaps.

Explain work using short, active sentences and consistent technical terms. Keep official command spelling. Apply the same communication and scope rules to each teammate.

## Route the limited command set

Use `$agent-team-lite` in Codex and `/agent-team-lite` in Claude Code. Clear plain-language equivalents work. These are skill instructions, not terminal commands.

| Action | Behavior |
| --- | --- |
| `start [task]` | Reserve the only team slot, plan one scoped task, then create or adopt its one feature worktree. With no task, take one ready unassigned item from the existing local task record; if none exists, report the missing scope. |
| `status` | Read this team's saved phase, task progress, blockers, and next action. No mutations, agent messages, fresh checks, or interruption. |
| `pause` | Stop new assignments and integration, save notes, and stop affected writers safely. Keep the slot and worktree reserved. |
| `resume` | Continue the same unfinished team and worktree after checking actual files and surviving writers. Do not create another team or restart completed steps. |

Reject team names/IDs as pause, resume, or status targets; reject `all`, `with-preview`, `approve`, dependency setup, and multi-team commands as unsupported in Lite. `start` accepts a task description, not a new named-team namespace. Explicit requests to launch multiple teams must be refused, not silently rewritten into one start. Explain the supported action without performing an unsupported request.

A development request while a team is unfinished belongs to that team only when it clearly continues the same task. A new independent task must wait. Never silently replace the existing task or fall through to the full skill. Natural-language requests to pause or resume use the same rules as the commands.

## Reserve the only team slot before work

Read [state and ownership](references/state.md) before start, pause, resume, handoff, or integration. Use the bundled `scripts/team-slot.sh` through a standard shell. Resolve the absolute installed skill path; run the helper from the target repository. It uses the shared Git metadata directory, so switching worktrees does not create another slot.

Acquire the slot BEFORE allocating a worktree, starting agents, or changing project records. Refuse a new start whenever a slot exists, including planning, developing, reviewing, paused, integrating, cleanup, partial initialization, and unknown/interrupted state. Say: **“Agent Team Lite already has an unfinished team in this repository. Resume or complete that team before starting another.”** Add the recorded task and phase if available.

Never bypass refusal with another branch, directory, session, renamed state folder, another copy of the skill, or automatic deletion of the slot. A stale timestamp does not establish that writers stopped. Do not start a Lite team alongside known active or paused full Agent-Team work in the same repository. Inspect existing project records and worktree ownership first; uncertain ownership is a blocker.

The slot prevents cooperative Lite starts within the same repository metadata. It does not police unrelated tools, independent clones, other machines, or arbitrary Git commands. Disclose this limit rather than promise a global process lock. If separate clones share the same project, use one designated checkout and do not start competing Lite work in another clone.

## Plan, develop, review, integrate

1. Read applicable project instructions and current Git changes. Resolve the primary checkout and existing planning files. Preserve user edits. Confirm a committed base exists and that the host can actually dispatch one developer and one reviewer. If unavailable, report the blocker; do not claim a team was started or automatically install dependencies.
2. After reserving the slot, write the scoped requirements, acceptance conditions, task ownership, and phase into `.agent-team-lite/TASKS.md` in the primary checkout. Reuse a suitable existing local task file by recording its canonical path, rather than keeping two live task ledgers. Record a short plan and next action in `.agent-team-lite/CONTEXT.md`. Only the orchestrator writes these records. Acceptance conditions describe the required result; they do not create a feature-testing stage.
3. Create exactly one feature branch/worktree from an identified commit, or adopt the recorded owned worktree on resume. Check `git worktree list --porcelain` and ownership before creation. All feature source changes, repairs, and merge-conflict repairs occur there. Never use automatic per-agent worktree isolation. Existing unrelated user worktrees are preserved, not counted as Lite-created worktrees, and not used for another Lite team.
4. Follow [host dispatch](references/hosts.md). Use one orchestrator, at most one developer, and at most one reviewer. Only the orchestrator spawns teammates. The developer writes the assigned feature files. The reviewer reads a stable revision and reports findings without changing source. Stop developer writes during review. All three use the same feature worktree when they inspect or modify feature code. Do not add specialists, nested teams, documentation agents, test agents, or another integrator.
5. Implement the simplest change that satisfies the recorded requirements. For UI changes, reuse the existing components and visual conventions; consider readable text, labels, keyboard access, spacing, and error states during source review. Do not install design tools or add browser-review machinery.
6. Run a focused source review and repair loop. Check the diff against requirements, obvious defects, scope, and maintainability. Do not create or run feature/unit/integration/end-to-end tests, automate browser tests, or claim runtime/visual validation. Do not add feature-code documentation or a documentation pass. Normal task and resume records are retained. Existing mandatory project/CI gates still apply: report a conflict or blocked gate rather than disable it or claim it passed. Optional build, lint, or type checks are allowed only when they are already available and materially needed; never describe them as proof of feature behavior. If a command includes tests, do not run it as a disguised build check.
7. Have the developer address concrete findings and the same reviewer re-read the affected diff. After two failed attempts without useful progress, change the approach within the same team. If still blocked, record the blocker and ask one focused question. Do not grow the team or add repeated review panels.
8. The orchestrator integrates the reviewed feature revision into main through the project's authorized Git process. There is no dedicated integration worktree or integrator agent. Follow [integration](references/integration.md): resolve conflicts in the existing feature worktree, re-review changed portions, and serialize changes to main. Preserve commit permissions and branch protection. Review success does not grant push, merge, or deployment permission.
9. Reconcile every requirement with source-review evidence and state the untested behavior clearly. Stop this team's writers/processes, preserve needed notes, and safely remove its feature worktree only after integration is confirmed and no unpreserved edits remain. Record the integrated revision and retained branch. Do not force-remove worktrees or delete user data. Release the slot only after the worktree is gone and integration is recorded. If integration or removal remains blocked, retain the slot in its unfinished phase. No automated deployment, rollback, or production cleanup is included.

## Preserve scope and recovery

Save short notes at phase changes, before pause, and when context is running low. Keep task status in the one task record; keep only current phase, branch/worktree, agent ownership, decisions, blockers, and next action in CONTEXT.md. No shared mistake database, multiple-team registry, cross-team handoffs, preview server, preview approval, or background monitor is included.

`pause` applies directly to the only team. Do not show a team picker. If writers cannot safely stop yet, record “pause pending” in notes and keep the current phase; do not report paused prematurely. `resume` retains the same task, slot, branch, and worktree. Confirm old writers have stopped before transferring ownership or replacing agents. If the worktree is missing, stop and report it; do not silently create a replacement or discard the slot. A crash does not imply a pause or a completed checkpoint.

Finish with a concise report: changed result, reviewed scope, checks actually run, feature behavior not tested, integration state, and remaining blockers. Do not say “tested” or “deployed” when those actions were not performed.
