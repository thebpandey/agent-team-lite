# Lite state, continuity, and readiness

The bundled helpers use only POSIX shell, Git, and ordinary system utilities. They are internal helpers, not user-facing skill commands. Run them from the target repository or any linked worktree, using the absolute installed-skill path.

`team-slot.sh` stores cooperative state in the canonical Git common directory at `agent-team-lite/`. A short-lived `operation.lock` directory atomically serializes each state mutation across linked worktrees. If it remains after a failed/interrupted mutation, preserve it and inspect the records, Git state, and writers; never clear it from age or PID reuse.

## Compatibility and two-team records

The legacy 6.1 record remains at `agent-team-lite/slot/` and its commands remain available:

| Internal operation | Purpose |
| --- | --- |
| `show` | Read the legacy record without writes. |
| `claim OWNER TASK ABSOLUTE_FEATURE_PATH` | Create the legacy reservation. |
| `phase OWNER NEXT_PHASE`, `resume OWNER`, `hold OWNER REASON`, `recover OWNER` | Advance, pause/resume, or hold/recover its lifecycle. |
| `next OWNER TASK ABSOLUTE_FEATURE_PATH` | Reuse a retained legacy reservation from `between`. |
| `finish OWNER FULL_INTEGRATED_COMMIT [retain]` | Record integration; `retain` moves it to `between`, otherwise releases it after the usual cleanup checks. |
| `adopt OLD_OWNER NEW_OWNER` | Optional audit-provenance update only. |

`OWNER` is audit provenance, never an authentication or historic-session lock. A fresh native session may use the normal legacy operations with its own recorded token after the host has reconciled actual writer liveness. Do not require `adopt` for ordinary continuation.

The explicit team-aware records live at `agent-team-lite/teams/TEAM/`, with `owner`, `task`, `main`, `worktree`, `phase`, and `owned` fields. Use these operations for up to two independent teams:

| Internal operation | Purpose |
| --- | --- |
| `team-admit TEAM OWNER TASK ABSOLUTE_WORKTREE_PATH OWNED...` | Atomically reserve a named team. Every `OWNED` entry is `path:ABSOLUTE_PATH` or `resource:ONE_LINE_ID`; the worktree location is implicitly owned. Paths are normalized first against proposed named worktree roots (even before Git creates them), then registered linked worktrees, so the same source through different future or existing worktree paths conflicts. |
| `team-show [TEAM]` | Read one/all named records without writes. |
| `team-phase TEAM NEXT_PHASE`, `team-hold TEAM REASON`, `team-recover TEAM` | Lifecycle operations with the same valid phases as the legacy record. `paused` preserves `previous`; a paused hold resumes to `held`. |
| `team-finish TEAM FULL_INTEGRATED_COMMIT [retain]` | Requires cleanup/between, no remaining/registered feature worktree, and main ancestry. `retain` records the commit and enters `between`; finish without it releases capacity. |
| `team-closeout TEAM FULL_INTEGRATED_COMMIT TARGET AUTHORITY RECEIPT OUTCOME` | Records the narrow closeout receipt required before release from `between`. `OUTCOME` is `disabled` or `succeeded`; `disabled` requires literal `disabled` placeholders for target, authority, and receipt, while `succeeded` requires exact non-`disabled` values for all three. |
| `team-adopt TEAM NEW_OWNER` | Optional audit-provenance update only, never a session-switch requirement. |

Named records share a limit of two active reservations. Admission is atomic under `operation.lock`: it rejects a third named claim, an existing team name, an incomplete record, duplicate resource ID, and equal/ancestor/descendant repository-relative or external path keys. A legacy 6.1 slot has no owned-source/resource fields, so mixed legacy/named admission fails closed in both directions; complete the legacy reservation or perform an evidence-backed migration before named admission. An incomplete legacy or named record is uncertain and blocks admission; preserve it for reconciliation.

The helper records cooperation safely but cannot inspect host agent/process liveness or writers outside its own invocation. A known-live or unknown writer remains occupied at the host level: do not replace it or reuse conflicting paths/resources. A missing session is not proof that it stopped. After actual host reconciliation, normal operations continue without the historical owner token.

## Shared integration

`integration acquire TEAM`, `integration release TEAM`, and `integration show` use `agent-team-lite/integration.lock/`. Only one named team can reserve main integration at once. Acquire requires `integrating`; release requires the same named reservation and `cleanup`, `between`, or `held`—a recorded safe endpoint phase. The helper does not prove that endpoint, gate results, or provider outcome. The orchestrator releases only after the shared-main writer stopped and its evidence is recorded.

`team-finish ... retain` enters `between` and cannot run while an integration lock exists. A later release requires a matching `team-closeout` receipt. Use `disabled disabled disabled disabled` only when auto-deploy is off. For an enabled successful deployment, use `succeeded` with exact target, authority, and receipt pointer. Unknown or failed deployment must remain held with evidence; it cannot release capacity.

## Read-only readiness

Run `sh /absolute/installed/skill/scripts/readiness.sh` before dispatch or when switching sessions. It never creates, repairs, locks, adopts, or removes files. It reports Git root, primary checkout, common directory, and committed base; the primary checkout's canonical task-ledger path and presence; active claim capacity (`0`–`2`), incomplete-state blocking, and any `operation.lock`; integration lock; and dispatch/gate/deployment facts.

Optional inputs are explicit, so missing facts stay visible rather than invented:

```sh
sh /absolute/installed/skill/scripts/readiness.sh \
  --ledger /absolute/project/.agent-team-lite/TASKS.md \
  --developer known --reviewer unknown --gates known \
  --gate-identities 'CI, source review' --gate-availability available \
  --auto-deploy-target unknown \
  --auto-deploy-mechanism unknown \
  --auto-deploy-authority unknown
```

`--developer`, `--reviewer`, and `--gates` accept only `known` or `unknown`; omitted values report `unknown`. `--gate-identities` and `--gate-availability` carry one-line observed facts and otherwise report `unknown`, so readiness never invents a gate or its availability. The three auto-deploy flags accept one-line recorded facts and likewise default to `unknown`. Readiness is evidence gathering, not readiness approval and not liveness proof.

There is no cancel, reset, force-start, lock reclamation, or arbitrary active-claim release command. If work must be abandoned, stop writers, preserve branches/files/notes, obtain explicit direction, and reconcile the record from evidence.
