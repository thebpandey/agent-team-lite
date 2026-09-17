#!/bin/sh
# Read-only Lite readiness facts for a repository or linked worktree.
set -eu
fail() { printf '%s\n' "$*" >&2; exit 1; }
one_line() {
    [ -n "$1" ] || fail 'Readiness values must not be empty'
    case "$1" in *'
'*) fail 'Readiness values must be one line' ;; esac
}
known_or_unknown() {
    case "$1" in known|unknown) ;; *) fail 'Expected known or unknown' ;; esac
}

root=$(git rev-parse --show-toplevel) || fail 'Run readiness from a Git working tree'
root=$(cd "$root" && pwd -P)
primary=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
[ -n "$primary" ] && [ -d "$primary" ] || fail 'Cannot resolve primary checkout'
primary=$(cd "$primary" && pwd -P)
common=$(git rev-parse --git-common-dir) || fail 'Cannot resolve Git common directory'
common=$(cd "$common" && pwd -P)
control="$common/agent-team-lite"
slot="$control/slot"
teams="$control/teams"
integration="$control/integration.lock"
operation="$control/operation.lock"
ledger="$primary/.agent-team-lite/TASKS.md"
developer=unknown
reviewer=unknown
gates=unknown
gate_identities=unknown
gate_availability=unknown
deploy_target=unknown
deploy_mechanism=unknown
deploy_authority=unknown

while [ "$#" -gt 0 ]; do
    case "$1" in
        --ledger) [ "$#" -ge 2 ] || fail '--ledger needs an absolute path'; ledger=$2; case "$ledger" in /*) ;; *) fail '--ledger needs an absolute path' ;; esac; one_line "$ledger"; shift 2 ;;
        --developer) [ "$#" -ge 2 ] || fail '--developer needs known or unknown'; developer=$2; known_or_unknown "$developer"; shift 2 ;;
        --reviewer) [ "$#" -ge 2 ] || fail '--reviewer needs known or unknown'; reviewer=$2; known_or_unknown "$reviewer"; shift 2 ;;
        --gates) [ "$#" -ge 2 ] || fail '--gates needs known or unknown'; gates=$2; known_or_unknown "$gates"; shift 2 ;;
        --gate-identities) [ "$#" -ge 2 ] || fail '--gate-identities needs a value'; gate_identities=$2; one_line "$gate_identities"; shift 2 ;;
        --gate-availability) [ "$#" -ge 2 ] || fail '--gate-availability needs a value'; gate_availability=$2; one_line "$gate_availability"; shift 2 ;;
        --auto-deploy-target) [ "$#" -ge 2 ] || fail '--auto-deploy-target needs a value'; deploy_target=$2; one_line "$deploy_target"; shift 2 ;;
        --auto-deploy-mechanism) [ "$#" -ge 2 ] || fail '--auto-deploy-mechanism needs a value'; deploy_mechanism=$2; one_line "$deploy_mechanism"; shift 2 ;;
        --auto-deploy-authority) [ "$#" -ge 2 ] || fail '--auto-deploy-authority needs a value'; deploy_authority=$2; one_line "$deploy_authority"; shift 2 ;;
        *) fail "Unknown readiness option: $1" ;;
    esac
done

base=$(git rev-parse --verify HEAD 2>/dev/null || :)
[ -n "$base" ] || base=unknown
active=0
unknown=false
if [ -e "$slot" ]; then
    active=$((active + 1))
    [ -d "$slot" ] && [ -f "$slot/owner" ] && [ -f "$slot/phase" ] && [ -f "$slot/worktree" ] || unknown=true
fi
if [ -e "$teams" ] && [ ! -d "$teams" ]; then
    unknown=true
elif [ -d "$teams" ]; then
    for record in "$teams"/*; do
        [ -e "$record" ] || continue
        active=$((active + 1))
        if [ ! -d "$record" ]; then
            unknown=true
            continue
        fi
        for field in owner task main worktree phase owned; do [ -f "$record/$field" ] || unknown=true; done
    done
fi
if [ "$active" -gt 2 ]; then unknown=true; fi
if [ -e "$operation" ]; then
    operation_state='unknown (mutation interrupted or active; admission blocked)'
    unknown=true
else
    operation_state=none
fi
if [ ! -e "$integration" ]; then
    integration_state=none
elif [ -d "$integration" ] && [ -f "$integration/team" ]; then
    integration_state=$(cat "$integration/team")
else
    integration_state='unknown (incomplete reservation; integration blocked)'
    unknown=true
fi

printf 'Git root: %s\n' "$root"
printf 'Primary checkout: %s\n' "$primary"
printf 'Git common directory: %s\n' "$common"
printf 'Committed base: %s\n' "$base"
printf 'Task ledger: %s (present: %s)\n' "$ledger" "$( [ -f "$ledger" ] && printf yes || printf no )"
printf 'Active claims: %s/2\n' "$active"
if [ "$unknown" = true ]; then
    printf 'Claim state: unknown (incomplete claim; admission blocked)\n'
elif [ "$active" -eq 2 ]; then
    printf 'Claim state: full (admission blocked)\n'
else
printf 'Claim state: known\n'
fi
printf 'Operation lock: %s\n' "$operation_state"
printf 'Integration lock: %s\n' "$integration_state"
printf 'Developer dispatch: %s\n' "$developer"
printf 'Reviewer dispatch: %s\n' "$reviewer"
printf 'Required project gates: %s\n' "$gates"
printf 'Required gate identities: %s\n' "$gate_identities"
printf 'Required gate availability: %s\n' "$gate_availability"
printf 'Auto-deploy target: %s\n' "$deploy_target"
printf 'Auto-deploy mechanism: %s\n' "$deploy_mechanism"
printf 'Auto-deploy authority: %s\n' "$deploy_authority"
