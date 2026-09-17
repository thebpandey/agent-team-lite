#!/bin/sh
# Package maintenance only; never a Lite feature-testing stage.
set -eu
helper=$(cd "$(dirname "$0")/../scripts" && pwd)/team-slot.sh
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
rev=$(git rev-parse HEAD)
call() { sh "$helper" "$@" >/dev/null; }
deny() { if call "$@" 2>/dev/null; then echo "Unexpected success: $*"; exit 1; fi; }
call show
[ ! -e .git/agent-team-lite ]
call claim owner first "$repo/feature"
deny claim other second "$repo/other"
# A new native session continues a complete reservation without knowing the
# historical owner token; owner remains audit provenance, not a mutation gate.
call phase fresh-session developing
call phase owner reviewing
call phase owner integrating
call phase owner cleanup
call finish owner "$rev" retain
[ "$(cat .git/agent-team-lite/slot/phase)" = between ]
deny claim other second "$repo/other"
call phase owner paused
deny next owner second "$repo/feature2"
call resume owner
call hold owner deployment-failure
deny next owner second "$repo/feature2"
deny finish owner "$rev"
call phase owner paused
call resume owner
[ "$(cat .git/agent-team-lite/slot/phase)" = held ]
call recover owner
call next owner second "$repo/feature2"
deny next owner third "$repo/feature3"
# The reservation is still occupied, but a reconciled new session may run the
# normal operation without recovering a historic owner token.
call phase other developing
call phase owner reviewing
call phase owner integrating
call phase owner cleanup
call finish owner "$rev" retain
call finish owner "$rev"
[ ! -d .git/agent-team-lite/slot ]
# Linked worktrees share the same guard, including concurrent claims.
git worktree add -q --detach "$repo/linked" HEAD
(sh "$helper" claim alpha task "$repo/a" >"$repo/a.log" 2>&1 && touch "$repo/a.won") &
a=$!
(cd "$repo/linked"; sh "$helper" claim beta task "$repo/b" >"$repo/b.log" 2>&1 && touch "$repo/b.won") &
b=$!
wait "$a" || :
wait "$b" || :
winners=0
[ ! -f "$repo/a.won" ] || winners=$((winners + 1))
[ ! -f "$repo/b.won" ] || winners=$((winners + 1))
[ "$winners" -eq 1 ]
owner=$(cat .git/agent-team-lite/slot/owner)
(cd "$repo/linked"; deny claim competitor task "$repo/c")
call phase "$owner" developing
call phase "$owner" reviewing
call phase "$owner" integrating
call phase "$owner" cleanup
feature=$(cat .git/agent-team-lite/slot/worktree)
mkdir "$feature"
deny finish "$owner" "$rev" retain
rmdir "$feature"
call finish "$owner" "$rev" retain
slot_inode=$(ls -di .git/agent-team-lite/slot | awk '{print $1}')
call next "$owner" next-task "$repo/next"
[ "$(ls -di .git/agent-team-lite/slot | awk '{print $1}')" = "$slot_inode" ]
mkdir .git/agent-team-lite/operation.lock
deny phase "$owner" developing
call show
[ -d .git/agent-team-lite/operation.lock ]
# A real failed atomic field rename must retain the recovery lock.
rmdir .git/agent-team-lite/operation.lock
mkdir -p .git/agent-team-lite/slot/phase.next
deny phase "$owner" developing
[ -d .git/agent-team-lite/operation.lock ]
[ "$(cat .git/agent-team-lite/slot/phase)" = planning ]
rmdir .git/agent-team-lite/slot/phase.next
# Simulate explicit maintenance reconciliation, not automatic stale recovery.
rmdir .git/agent-team-lite/operation.lock
rm .git/agent-team-lite/slot/phase
deny claim competitor task "$repo/c"
deny phase "$owner" developing
call show
echo 'Concurrent linked-worktree claims, retained slot identity, cleanup guards, and interrupted state passed.'
echo 'Serial transitions, pause, hold, recovery, and release passed.'

# Team-aware admission is shared by linked worktrees. The first reservation
# owns both its worktree path and its declared paths/resources; a nested path
# or duplicate resource must be denied before capacity is reached.
teamrepo=$(mktemp -d)
trap 'rm -rf "$repo" "$teamrepo"' EXIT
cd "$teamrepo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
teamrev=$(git rev-parse HEAD)
git worktree add -q --detach "$teamrepo/linked" HEAD
call team-admit alpha alpha-session alpha-task "$teamrepo/team-alpha" "path:$teamrepo/source" "resource:database-alpha"
deny team-admit beta beta-session nested-path "$teamrepo/team-beta" "path:$teamrepo/source/child" "resource:database-beta"
deny team-admit beta beta-session duplicate-resource "$teamrepo/team-beta" "path:$teamrepo/other" "resource:database-alpha"
(cd "$teamrepo/linked"; call team-admit beta beta-session beta-task "$teamrepo/team-beta" "path:$teamrepo/other" "resource:database-beta")
[ -d .git/agent-team-lite/teams/alpha ]
[ -d .git/agent-team-lite/teams/beta ]
deny team-admit gamma gamma-session third-task "$teamrepo/team-gamma" "path:$teamrepo/third" "resource:database-gamma"
# Fresh sessions can continue a team without an owner-token handoff.
call team-phase alpha developing
(cd "$teamrepo/linked"; call team-phase alpha reviewing)
call team-phase alpha integrating
call integration acquire alpha
integration_report=$(sh "$helper" integration show)
[ "$integration_report" = 'integration team: alpha' ]
deny integration acquire beta
call team-phase alpha cleanup
deny team-finish alpha "$teamrev" retain
call integration release alpha
call team-finish alpha "$teamrev" retain
[ "$(cat .git/agent-team-lite/teams/alpha/phase)" = between ]
call team-hold alpha deployment-outcome-pending
call team-recover alpha
deny team-finish alpha "$teamrev"
deny team-closeout alpha "$teamrev" disabled disabled disabled failed
deny team-closeout alpha "$teamrev" disabled disabled disabled unknown
call team-closeout alpha "$teamrev" disabled disabled disabled disabled
call team-finish alpha "$teamrev"
[ ! -d .git/agent-team-lite/teams/alpha ]
# An incomplete claim is uncertain and therefore blocks admission fail-closed.
mkdir .git/agent-team-lite/teams/uncertain
deny team-admit gamma gamma-session uncertain-replacement "$teamrepo/team-gamma" "path:$teamrepo/third" "resource:database-gamma"
echo 'Two-team admission, path/resource exclusion, serial integration, cross-session continuation, and incomplete-state blocking passed.'

# Legacy slots lack source/resource ownership, so mixed admission fails closed
# in both directions rather than treating an old slot as safely independent.
mixedrepo=$(mktemp -d)
trap 'rm -rf "$repo" "$teamrepo" "$mixedrepo"' EXIT
cd "$mixedrepo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
call team-admit alpha alpha-session alpha-task "$mixedrepo/team-alpha" "path:$mixedrepo/source" "resource:database-alpha"
deny claim legacy legacy-task "$mixedrepo/legacy"
legacyrepo=$(mktemp -d)
trap 'rm -rf "$repo" "$teamrepo" "$mixedrepo" "$legacyrepo"' EXIT
cd "$legacyrepo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
call claim legacy legacy-task "$legacyrepo/legacy"
deny team-admit beta beta-session named-task "$legacyrepo/team-beta" "path:$legacyrepo/source" "resource:database-beta"
echo 'Mixed legacy/team admission fails closed passed.'

# A source owned through separate linked-worktree absolute paths has one
# repository-relative claim key and must collide.
relrepo=$(mktemp -d)
trap 'rm -rf "$repo" "$teamrepo" "$mixedrepo" "$legacyrepo" "$relrepo"' EXIT
cd "$relrepo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
git worktree add -q --detach "$relrepo/linked" HEAD
call team-admit alpha alpha-session alpha-task "$relrepo/team-alpha" "path:$relrepo/src/shared.js" "resource:database-alpha"
(cd "$relrepo/linked"; deny team-admit beta beta-session shared-source "$relrepo/team-beta" "path:$relrepo/linked/src/shared.js" "resource:database-beta")
echo 'Repository-relative owned source collision across linked worktrees passed.'

# Admission happens before feature-worktree creation.  Proposed worktree
# roots must therefore normalize their own future source paths before Git can
# register either worktree.
futurerepo=$(mktemp -d)
trap 'rm -rf "$repo" "$teamrepo" "$mixedrepo" "$legacyrepo" "$relrepo" "$futurerepo"' EXIT
cd "$futurerepo"
git init -q
git -c user.name=Check -c user.email=check@example.invalid commit -qm base --allow-empty
call team-admit alpha alpha-session alpha-task "$futurerepo/team-a" "path:$futurerepo/team-a/src/shared.js" "resource:database-alpha"
deny team-admit beta beta-session shared-future-source "$futurerepo/team-b" "path:$futurerepo/team-b/src/shared.js" "resource:database-beta"
call team-admit beta beta-session disjoint-future-source "$futurerepo/team-b" "path:$futurerepo/team-b/src/other.js" "resource:database-beta"
echo 'Repository-relative owned source collision across future worktrees passed.'
