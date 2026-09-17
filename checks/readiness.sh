#!/bin/sh
# Package-maintenance coverage for the read-only readiness reporter.
set -eu
ready=$(cd "$(dirname "$0")/../scripts" && pwd)/readiness.sh
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
base=$(git rev-parse HEAD)

# An empty project gets a complete unknown-safe report without state creation.
report=$(sh "$ready" --developer known --reviewer unknown --gates known --gate-identities 'CI, source review' --gate-availability available --auto-deploy-target unknown --auto-deploy-mechanism unknown --auto-deploy-authority unknown)
[ ! -e .git/agent-team-lite ]
[ ! -e .agent-team-lite ]
printf '%s\n' "$report" | grep -F "Git root: $repo" >/dev/null
printf '%s\n' "$report" | grep -F "Committed base: $base" >/dev/null
printf '%s\n' "$report" | grep -F 'Task ledger: ' >/dev/null
printf '%s\n' "$report" | grep -F 'present: no' >/dev/null
printf '%s\n' "$report" | grep -F 'Active claims: 0/2' >/dev/null
printf '%s\n' "$report" | grep -F 'Developer dispatch: known' >/dev/null
printf '%s\n' "$report" | grep -F 'Reviewer dispatch: unknown' >/dev/null
printf '%s\n' "$report" | grep -F 'Required project gates: known' >/dev/null
printf '%s\n' "$report" | grep -F 'Required gate identities: CI, source review' >/dev/null
printf '%s\n' "$report" | grep -F 'Required gate availability: available' >/dev/null
printf '%s\n' "$report" | grep -F 'Auto-deploy target: unknown' >/dev/null

# Existing state is reported, including an incomplete claim and integration
# lock, without repair, lock reclamation, or other mutation.
mkdir -p .agent-team-lite .git/agent-team-lite/teams/uncertain .git/agent-team-lite/integration.lock .git/agent-team-lite/operation.lock
printf 'primary ledger\n' > .agent-team-lite/TASKS.md
printf 'alpha\n' > .git/agent-team-lite/integration.lock/team
before=$(find .git/agent-team-lite -type f -exec cksum {} \; | sort)
report=$(sh "$ready")
after=$(find .git/agent-team-lite -type f -exec cksum {} \; | sort)
[ "$before" = "$after" ]
printf '%s\n' "$report" | grep -F 'Active claims: 1/2' >/dev/null
printf '%s\n' "$report" | grep -F 'Claim state: unknown (incomplete claim; admission blocked)' >/dev/null
printf '%s\n' "$report" | grep -F 'Operation lock: unknown (mutation interrupted or active; admission blocked)' >/dev/null
printf '%s\n' "$report" | grep -F 'Integration lock: alpha' >/dev/null
printf '%s\n' "$report" | grep -F 'Developer dispatch: unknown' >/dev/null
printf '%s\n' "$report" | grep -F 'Auto-deploy authority: unknown' >/dev/null
# The default ledger comes from the primary checkout, not this linked path.
git worktree add -q --detach "$repo/linked" HEAD
linked_report=$(cd "$repo/linked" && sh "$ready")
printf '%s\n' "$linked_report" | grep -F "Task ledger: $repo/.agent-team-lite/TASKS.md (present: yes)" >/dev/null
echo 'Read-only readiness reports project facts, capacity, safeguards, and explicit unknowns without writes.'
