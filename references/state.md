# Single-team state and ownership

The slot helper requires only a standard shell, Git, and ordinary system utilities. Run it from the project or any linked worktree with `sh /absolute/installed/skill/scripts/team-slot.sh ...`. These are internal helpers, not extra user-facing skill commands.

The helper stores its reservation under the canonical Git common directory at `agent-team-lite/slot`. `mkdir` reserves an operation lock atomically so concurrent starts cannot both succeed. The slot remains present for the entire unfinished task, including pauses. The separate operation lock lasts only for a state mutation. A process crash can leave it behind; refuse further mutations until its owner and the pending operation have been inspected. Do not reclaim it solely from age or PID reuse.

The orchestrator owns task/resume notes in the primary checkout. Record the absolute task-file path, primary branch, session identity, helper-owner token, task description, feature branch/path, base commit, teammate identities, reviewed revision, blockers, and next action. The token distinguishes cooperative owners; it is not a security credential or authentication barrier. Teammates never call the helper.

| Internal operation | When to use |
| --- | --- |
| `show` | Read the slot without creating files. Partial state is unfinished, not empty. |
| `claim OWNER TASK ABSOLUTE_FEATURE_PATH` | Reserve once before project mutations, worktree creation, or agent dispatch. OWNER is the current host/session identity or a uniquely recorded opaque identifier. The path must be unused. |
| `phase OWNER developing` | Begin implementation after planning and creation of the one worktree. |
| `phase OWNER reviewing` | Freeze writes for source review. |
| `phase OWNER integrating` | Begin integration of the reviewed revision. |
| `phase OWNER cleanup` | Integration is confirmed; finish records and safe worktree removal. |
| `phase OWNER paused` | Only after affected writers and integration have stopped safely. Previous phase is saved. |
| `resume OWNER` | Restore the saved phase of the same paused team. Check files and processes first. |
| `adopt OLD_OWNER NEW_OWNER` | Transfer the existing slot only after confirming the old orchestrator and teammate writers stopped, or a coordinated handoff completed. |
| `finish OWNER FULL_INTEGRATED_COMMIT` | Release after integration evidence is recorded, writers stopped, and the feature worktree is removed. The helper checks cleanup phase, worktree absence, and ancestry of the recorded integration revision. |

Always quote arguments and use tool-supported structured arguments or proper shell quoting for user task text. Never use `eval`, execute task text, or source slot files as shell code. Feature paths must be absolute, newline-free paths supplied as data.

## Resume without a second team

Read slot state, canonical task/resume notes, `git worktree list --porcelain`, branch revisions, dirty files, and host agent/process state. Treat the actual source as authoritative. Active known writers prevent replacement; attach to them where supported. A missing session is not proof that its processes ended. If the old owner has demonstrably stopped, adopt the same reservation and replace only stopped teammate roles. Never create a second orchestrator as an integration worker.

Planning may have reserved a path before creating the worktree. Resume may create that one recorded path only when evidence confirms no feature worktree was ever created. If development had begun and its worktree disappeared, report lost/missing work; do not silently replace it. If phase is cleanup and notes plus current Git state confirm removal already succeeded, finish the same slot. If phase says integration but evidence proves the merge completed, record that evidence and continue cleanup without merging again.

No slot but existing unfinished Lite notes or an owned feature worktree is inconsistent state. Block new start, investigate, and restore ownership only from evidence. Do not interpret a lost guard as permission for another team. Partial claim or interrupted operation likewise requires reconciliation; never delete it merely to make start work.

There is no cancel, reset, or force-start command. If a task must be abandoned, get explicit instructions, stop all writers, preserve the branch/files/notes, and reconcile the reservation as a separate recovery operation. Do not build an abandonment shortcut into start or resume.

The helper enforces reservation and phase checks for cooperating invocations. Worktree count, agent liveness, source review, permissions, and complete integration evidence also require the orchestrator's checks. Do not claim that shell metadata can enforce these across independent clones or hosts.
