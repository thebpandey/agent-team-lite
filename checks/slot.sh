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
call phase owner developing
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
deny phase other developing
call phase owner developing
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
mkdir "$repo/$( [ "$owner" = alpha ] && echo a || echo b )"
deny finish "$owner" "$rev" retain
rmdir "$repo/$( [ "$owner" = alpha ] && echo a || echo b )"
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
