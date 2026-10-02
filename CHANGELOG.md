# Changelog

Semantic versioning uses MAJOR.MINOR.PATCH. `metadata.version` in SKILL.md is authoritative.

## Unreleased

- Add a per-team progress checklist with loop-backs for review findings and integration conflicts.
- Add informational `metadata.intended_model`.

## 6.2.0 — 2026-09-16

- Support up to two disjoint teams with serial integration for each team.
- Preserve same-project session continuity without an owner gate, while retaining live-writer safety.
- Add read-only readiness and durable observed host, model, revision, and gate evidence.
- Require exact-revision closeout and deployment evidence for authorized runs.
- Add dependency-free package integrity checks, exact-revision ZIPs, and CI coverage.

## 6.1.0 — 2026-09-06

First recorded Lite semantic release, numbered 6.1.0 at the maintainer's explicit request. Previous repository commits were unversioned; this number does not imply full-edition feature parity.

- Add installed-version display, solid wordmark with lowercase lite, creator/source attribution, and consistent message borders.
- Add read-only help and two project defaults: continuous and auto-deploy, both off by default, with explicit run overrides.
- Add serialized continuous scheduling under one retained repository reservation, between-task checkpoints, pause recovery, and deployment-failure holds.
- Permit limited per-task deployment through the project's existing authorized mechanism; retain all other Lite edition boundaries.
- Update host metadata and installation guidance; add focused isolated slot-maintenance checks.
