# Native host dispatch

Use only the adapter for the actual host. Do not import another skill or install a plugin. The root conversation is the orchestrator and integrator; a skill cannot change its own parent model. A Codex or Claude Code session may continue an already-recorded Lite project on the same Git repository. A recorded owner or session is audit provenance, not a normal mutation gate: reconcile current files, pending operations, and writer liveness first; prove writers stopped only before replacing them or claiming overlapping paths.

## Codex

Invoke `$agent-team-lite`. Use the available native agent controls. Keep the configured parent model. Select an available coding-capable developer and independent reviewer using the user's existing model policy; the same model may fill both roles through distinct agents. If the host exposes Terra, it is a suitable default for standard development and review. Do not create a separate complex-developer role. When a harder task needs a different model, replace the developer only after it has stopped; keep one developer slot per active team. Enforce actual model/effort through supported tool fields and report unavailable required settings.

Send the absolute feature-worktree path and explicitly disable additional worktrees. Use bounded task context and current source evidence. Developers and reviewers must not spawn agents. Reuse the same agents across repair rounds when possible.

## Claude Code

Invoke `/agent-team-lite` in the main conversation. Use Claude Code's native agent mechanism with a coding-capable developer and a separate source reviewer. Use the user's configured model policy and supported per-call settings; do not invent model IDs or claim an effort setting that the host cannot enforce. Do not use a text-only model for code review. Keep the orchestrator in the main conversation, not a forked skill context.

Use native subagents in the specified existing worktree. Do not request automatic worktree isolation, experimental multi-team mode, or an additional full session. If native dispatch cannot keep each active team to one worktree, one developer, and one independent reviewer, report that limitation before implementation. No role-registration installer or external package is required by Lite.

## Dispatch contract for both hosts

Before each dispatch, perform a read-only readiness check and record it in the existing `.agent-team-lite/CONTEXT.md`: observed host and continuation session, primary checkout and input revision, task/worktree identity, developer and reviewer role/model/effort actually selected, capacity, and the identity/availability of mandatory gates. Readiness is evidence, not setup: do not install dependencies, start a server, create a preview, or run tests. A missing committed base, unavailable independent reviewer capacity, unknown task ownership, or unknown mandatory-gate identity/availability blocks admission. Record mandatory-gate results before integration/deployment; do not treat their future result as an admission fact. For enabled deployment, also record the known target, mechanism, authority pointer, and revision-to-deploy before submission; unknown or drifting facts hold that team.

At every handoff, review, integration, and deployment boundary, append the observed revision, mandatory-gate state, actor/host, evidence pointer or command receipt, and next action to that same CONTEXT.md. Record observed facts rather than inferred capability. These records are durable coordination evidence; they do not create a separate tracker, host registry, test stage, or feature documentation.

Give each teammate the task, owned paths, absolute worktree, relevant project rules, required result, and current revision. Include these rules verbatim in substance:

- Work only on this task in this worktree. Do not create branches/worktrees, merge, push, deploy, spawn teammates, or change Lite reservation state.
- Developer: write only assigned feature files. Reviewer: read stable source and return concrete findings; do not edit source.
- Do not write code documentation, create/run feature tests, use browser automation, or invoke external skills/plugins.
- Report required project checks that conflict with the Lite scope. Do not bypass them.
- Frame user-facing and relayed messages using [Lite output](output.md), with the Lite Developer/Reviewer role and no nested frames. Native tool payloads remain unchanged.
- Send concise evidence and next action to the orchestrator, who alone updates task/resume records.
- On pause, stop safely and report remaining activity; do not claim you stopped until writes are finished.

A native tool permission boundary is stronger than a prompt. Apply supported restrictions where available, but do not claim the prompt itself prevents arbitrary actions outside the cooperative workflow.
