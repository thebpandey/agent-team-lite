#!/bin/sh
# Cooperative Lite reservations, shared by all linked Git worktrees.
set -eu
fail() { printf '%s\n' "$*" >&2; exit 1; }
common=$(git rev-parse --git-common-dir) || exit 1
common=$(cd "$common" && pwd -P)
control="$common/agent-team-lite"
slot="$control/slot"
teams="$control/teams"
integration="$control/integration.lock"
action=${1:-show}
[ "$#" -eq 0 ] || shift
read_field() { cat "$slot/$1"; }
read_team_field() { cat "$teams/$1/$2"; }
show() {
    if [ ! -d "$slot" ]; then
        printf 'No reserved Lite team.\n'
        return
    fi
    for field in phase owner task main worktree previous integrated reason held_from; do
        if [ -f "$slot/$field" ]; then
            printf '%s: ' "$field"
            read_field "$field"
        fi
    done
    [ -f "$slot/phase" ] || printf 'phase: unknown (incomplete claim; start remains blocked)\n'
}
[ "$action" != show ] || { [ "$#" -eq 0 ] || fail 'show takes no arguments'; show; exit; }
team_show() {
    [ "$#" -le 1 ] || fail 'team-show takes zero or one TEAM argument'
    [ -d "$teams" ] || { printf 'No team-aware Lite reservations.\n'; return; }
    if [ "$#" -eq 1 ]; then
        team=$1
        [ -d "$teams/$team" ] || fail 'No such team-aware reservation'
        set -- "$teams/$team"
    else
        set -- "$teams"/*
    fi
    for record in "$@"; do
        [ -e "$record" ] || continue
        team=$(basename "$record")
        printf 'team: %s\n' "$team"
        for field in phase owner task main worktree previous integrated deploy_commit deploy_target deploy_authority deploy_receipt deploy_outcome reason held_from owned; do
            if [ -f "$record/$field" ]; then
                printf '  %s: ' "$field"
                cat "$record/$field"
            fi
        done
        [ -f "$record/phase" ] || printf '  phase: unknown (incomplete claim; admission remains blocked)\n'
    done
}
integration_show() {
    if [ ! -d "$integration" ]; then
        printf 'No integration reservation.\n'
    elif [ -f "$integration/team" ]; then
        printf 'integration team: '
        cat "$integration/team"
    else
        printf 'integration: unknown (incomplete reservation; integration remains blocked)\n'
    fi
}
case "$action" in
    team-show) team_show "$@"; exit ;;
esac
if [ "$action" = integration ] && [ "${1:-show}" = show ]; then
    [ "$#" -eq 1 ] || fail 'integration show takes no further arguments'
    integration_show
    exit
fi
case "$action" in claim|phase|resume|adopt|finish|next|hold|recover|team-admit|team-phase|team-hold|team-recover|team-finish|team-closeout|team-adopt|integration) ;; *) fail 'Internal actions: show, claim, phase, resume, adopt, finish, next, hold, recover, team-admit, team-show, team-phase, team-hold, team-recover, team-finish, team-closeout, team-adopt, integration' ;; esac
mkdir -p "$control"
mkdir "$control/operation.lock" 2>/dev/null || fail 'Another slot operation is active or interrupted. Inspect ownership; do not auto-clear its lock.'
mutation_started=false
operation_complete=false
trap 'if [ "$mutation_started" = false ] || [ "$operation_complete" = true ]; then rmdir "$control/operation.lock"; fi' EXIT
trap 'exit 1' HUP INT TERM
printf '%s\n' "$$" > "$control/last-operation-pid"
one_line() {
    [ -n "$1" ] || fail 'Empty field is not allowed'
    case "$1" in *'
'*) fail 'Fields must be one line' ;; esac
}
write_at() { mutation_started=true; printf '%s\n' "$3" > "$1/$2.next"; mv "$1/$2.next" "$1/$2"; }
write_field() { write_at "$slot" "$1" "$2"; }
owned() {
    [ -d "$slot" ] || fail 'No reserved team'
    [ -f "$slot/owner" ] && [ -f "$slot/phase" ] || fail 'Incomplete claim: preserve it and inspect before recovery'
}
has_named_records() {
    [ -d "$teams" ] || return 1
    for record in "$teams"/*; do [ -e "$record" ] && return 0; done
    return 1
}
team_id() {
    one_line "$1"
    case "$1" in *[!A-Za-z0-9_-]*|'') fail 'TEAM must contain only letters, digits, hyphen, or underscore' ;; esac
}
canonical_path() {
    one_line "$1"
    case "$1" in /*) ;; *) fail 'Owned paths must be absolute' ;; esac
    case "$1" in *'//'*|*'/./'*|*'/../'|*/.|*/..) fail 'Owned paths must not contain empty, dot, or dot-dot components' ;; esac
    candidate=$1
    while [ "$candidate" != / ] && [ "${candidate%/}" != "$candidate" ]; do candidate=${candidate%/}; done
    probe=$candidate
    suffix=
    while [ ! -e "$probe" ] && [ "$probe" != / ]; do
        leaf=$(basename "$probe")
        suffix="/$leaf$suffix"
        probe=$(dirname "$probe")
    done
    [ -e "$probe" ] || fail 'Cannot resolve owned path'
    if [ -d "$probe" ]; then
        resolved=$(cd "$probe" && pwd -P)
    else
        resolved=$(cd "$(dirname "$probe")" && pwd -P)/$(basename "$probe")
    fi
    printf '%s\n' "$resolved$suffix"
}
team_record_complete() {
    record=$1
    [ -d "$record" ] || return 1
    for field in owner task main worktree phase owned; do [ -f "$record/$field" ] || return 1; done
}
assert_no_uncertain_teams() {
    [ -d "$teams" ] || return 0
    for record in "$teams"/*; do
        [ -e "$record" ] || continue
        team_record_complete "$record" || fail 'Incomplete team-aware claim: preserve it and inspect before admission'
    done
}
assert_legacy_complete() {
    [ ! -e "$slot" ] && return
    [ -d "$slot" ] && [ -f "$slot/owner" ] && [ -f "$slot/phase" ] || fail 'Incomplete legacy claim: preserve it and inspect before admission'
}
active_claim_count() {
    count=0
    [ ! -e "$slot" ] || count=$((count + 1))
    if [ -d "$teams" ]; then
        for record in "$teams"/*; do [ -e "$record" ] || continue; count=$((count + 1)); done
    fi
    printf '%s\n' "$count"
}
paths_overlap() {
    left=$1 right=$2
    [ "$left" = "$right" ] && return 0
    case "$left/" in "$right/"*) return 0 ;; esac
    case "$right/" in "$left/"*) return 0 ;; esac
    return 1
}
repo_paths_overlap() {
    left=$1 right=$2
    [ "$left" = . ] || [ "$right" = . ] || paths_overlap "$left" "$right"
}
owned_key_for_path() {
    main=$1 candidate=$2 proposed=$3
    best=
    for registered in "$proposed"; do
        registered=$(canonical_path "$registered")
        case "$candidate" in "$registered"|"$registered"/*)
            if [ -z "$best" ] || [ "${#registered}" -gt "${#best}" ]; then best=$registered; fi
            ;;
        esac
    done
    if [ -d "$teams" ]; then
        for record in "$teams"/*; do
            [ -f "$record/worktree" ] || continue
            registered=$(canonical_path "$(cat "$record/worktree")")
            case "$candidate" in "$registered"|"$registered"/*)
                if [ -z "$best" ] || [ "${#registered}" -gt "${#best}" ]; then best=$registered; fi
                ;;
            esac
        done
    fi
    while IFS= read -r registered; do
        registered=$(canonical_path "$registered")
        case "$candidate" in "$registered"|"$registered"/*)
            if [ -z "$best" ] || [ "${#registered}" -gt "${#best}" ]; then best=$registered; fi
            ;;
        esac
    done <<EOF
$(git -C "$main" worktree list --porcelain | sed -n 's/^worktree //p')
EOF
    if [ -n "$best" ]; then
        if [ "$candidate" = "$best" ]; then printf 'repo:.\n'; else printf 'repo:%s\n' "${candidate#"$best"/}"; fi
        return 0
    fi
    printf 'path:%s\n' "$candidate"
}
owned_keys_overlap() {
    existing=$1 requested=$2
    case "$existing:$requested" in
        repo:*:repo:*) repo_paths_overlap "${existing#repo:}" "${requested#repo:}" ;;
        resource:*:resource:*) [ "${existing#resource:}" = "${requested#resource:}" ] ;;
        path:*:path:*|path:*:worktree:*|worktree:*:path:*|worktree:*:worktree:*)
            paths_overlap "${existing#*:}" "${requested#*:}" ;;
        *) return 1 ;;
    esac
}
assert_disjoint_ownership() {
    candidate=$1
    if [ -d "$slot" ] && [ -f "$slot/worktree" ]; then
        legacy_path=$(canonical_path "$(read_field worktree)")
        while IFS= read -r requested; do
            case "$requested" in path:*) paths_overlap "$legacy_path" "${requested#path:}" && fail 'DENIED: owned path overlaps the legacy reservation' ;; esac
        done < "$candidate"
    fi
    [ -d "$teams" ] || return 0
    for record in "$teams"/*; do
        [ -e "$record" ] || continue
        while IFS= read -r existing; do
            while IFS= read -r requested; do
                owned_keys_overlap "$existing" "$requested" && fail "DENIED: owned path or resource overlaps team $(basename "$record")"
            done < "$candidate"
        done < "$record/owned"
    done
    return 0
}
team_owned() {
    team=$1
    record="$teams/$team"
    team_record_complete "$record" || fail 'Incomplete team-aware claim: preserve it and inspect before recovery'
}
case "$action" in
claim)
    [ "$#" -eq 3 ] || fail 'claim OWNER TASK ABSOLUTE_FEATURE_PATH'
    one_line "$1"; one_line "$2"; one_line "$3"
    if [ -e "$slot" ]; then
        show
        fail 'DENIED: Agent Team Lite already has an unfinished team in this repository. Resume or complete that team before starting another.'
    fi
    case "$3" in /*) ;; *) fail 'Feature path must be absolute' ;; esac
    has_named_records && fail 'DENIED: named reservations cannot mix with a legacy slot lacking owned source/resource evidence'
    [ ! -e "$3" ] || fail 'New feature path already exists; inspect it instead of creating duplicate work'
    main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
    [ -n "$main" ] && [ -d "$main" ] || fail 'Cannot resolve primary checkout'
    one_line "$main"
    [ "$(git -C "$main" rev-parse --is-bare-repository)" = false ] || fail 'A primary working checkout is required'
    git -C "$main" rev-parse --verify HEAD >/dev/null || fail 'A committed base is required'
    mutation_started=true
    mkdir "$slot" || fail 'Could not reserve the only team slot'
    write_field owner "$1"
    write_field task "$2"
    write_field main "$main"
    write_field worktree "$3"
    write_field phase planning
    show
    ;;
phase)
    [ "$#" -eq 2 ] || fail 'phase OWNER NEXT_PHASE'
    owned "$1"
    current=$(read_field phase)
    next=$2
    case "$current:$next" in
        planning:developing|developing:reviewing|reviewing:developing|reviewing:integrating|integrating:developing|integrating:reviewing|integrating:cleanup) ;;
        planning:paused|developing:paused|reviewing:paused|integrating:paused|cleanup:paused|between:paused|held:paused)
            write_field previous "$current" ;;
        *) fail "Unsupported phase transition: $current -> $next" ;;
    esac
    write_field phase "$next"
    show
    ;;
resume)
    [ "$#" -eq 1 ] || fail 'resume OWNER'
    owned "$1"
    [ "$(read_field phase)" = paused ] || fail 'Team is not paused; inspect and continue its recorded stage without a new claim'
    previous=$(read_field previous)
    case "$previous" in planning|developing|reviewing|integrating|cleanup|between|held) ;; *) fail 'Invalid saved phase; inspect state' ;; esac
    write_field phase "$previous"
    show
    ;;
adopt)
    [ "$#" -eq 2 ] || fail 'adopt OLD_OWNER NEW_OWNER (only after confirming old writers stopped)'
    owned "$1"
    one_line "$2"
    write_field owner "$2"
    show
    ;;
hold)
    [ "$#" -eq 2 ] || fail 'hold OWNER REASON'
    owned "$1"; one_line "$2"
    current=$(read_field phase)
    case "$current" in paused|held) fail 'Preserve existing pause/hold; record additional reason in notes' ;; esac
    write_field held_from "$current"
    write_field reason "$2"
    write_field phase held
    show
    ;;
recover)
    [ "$#" -eq 1 ] || fail 'recover OWNER (only after reconciling the recorded blocker)'
    owned "$1"
    [ "$(read_field phase)" = held ] || fail 'Recovery requires held phase'
    prior=$(read_field held_from)
    case "$prior" in planning|developing|reviewing|integrating|cleanup|between) ;; *) fail 'Invalid held phase' ;; esac
    write_field phase "$prior"
    show
    ;;
next)
    [ "$#" -eq 3 ] || fail 'next OWNER TASK ABSOLUTE_FEATURE_PATH'
    owned "$1"; one_line "$2"; one_line "$3"
    [ "$(read_field phase)" = between ] || fail 'Next task requires completed cleanup and no pause/hold'
    case "$3" in /*) ;; *) fail 'Feature path must be absolute' ;; esac
    has_named_records && fail 'DENIED: named reservations cannot mix with a legacy slot lacking owned source/resource evidence'
    [ ! -e "$3" ] && [ ! -L "$3" ] || fail 'Next feature path already exists'
    if git worktree list --porcelain | grep -F -x -e "worktree $3" >/dev/null; then
        fail 'Next path is already registered'
    fi
    write_field task "$2"
    write_field worktree "$3"
    write_field phase planning
    show
    ;;
finish)
    [ "$#" -eq 2 ] || [ "$#" -eq 3 ] || fail 'finish OWNER RECORDED_INTEGRATED_COMMIT [retain]'
    mode=${3:-release}
    case "$mode" in retain|release) ;; *) fail 'Expected retain or no third argument' ;; esac
    owned "$1"
    case "$(read_field phase)" in cleanup|between) ;; *) fail 'Finish requires cleanup or between phase after integration' ;; esac
    feature=$(read_field worktree)
    [ ! -e "$feature" ] && [ ! -L "$feature" ] || fail 'Feature worktree still exists; slot remains reserved'
    if git worktree list --porcelain | grep -F -x -e "worktree $feature" >/dev/null; then
        fail 'Feature worktree is still registered; slot remains reserved'
    fi
    main=$(read_field main)
    case "$2" in ''|*[!0-9a-fA-F]*) fail 'Pass the recorded full hexadecimal integrated commit ID' ;; esac
    [ "${#2}" -ge 40 ] || fail 'Full integrated commit ID is required'
    integrated=$(git -C "$main" rev-parse --verify "$2^{commit}") || fail 'Invalid integration revision'
    git -C "$main" merge-base --is-ancestor "$integrated" HEAD || fail 'Recorded integration revision is not present in the primary checkout'
    write_field integrated "$integrated"
    if [ "$mode" = retain ]; then
        write_field phase between
        show
        operation_complete=true
        exit
    fi
    write_field phase complete
    archive="$control/completed-$(date +%s)-$$"
    [ ! -e "$archive" ] || fail 'Completion archive collision; preserve state'
    mv "$slot" "$archive"
    printf 'Team completed; only team slot released. Receipt: %s\n' "$archive"
    ;;
team-admit)
    [ "$#" -ge 5 ] || fail 'team-admit TEAM OWNER TASK ABSOLUTE_WORKTREE_PATH OWNED...'
    team=$1 owner=$2 task=$3 worktree=$4
    shift 4
    team_id "$team"; one_line "$owner"; one_line "$task"
    [ ! -e "$slot" ] || fail 'DENIED: legacy reservation lacks owned source/resource evidence; complete it or perform an evidence-backed migration before named admission'
    assert_no_uncertain_teams
    [ ! -e "$teams/$team" ] || fail 'A team-aware reservation with this TEAM already exists'
    [ "$(active_claim_count)" -lt 2 ] || fail 'DENIED: two Lite teams are already active in this repository'
    main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
    [ -n "$main" ] && [ -d "$main" ] || fail 'Cannot resolve primary checkout'
    [ "$(git -C "$main" rev-parse --is-bare-repository)" = false ] || fail 'A primary working checkout is required'
    git -C "$main" rev-parse --verify HEAD >/dev/null || fail 'A committed base is required'
    worktree=$(canonical_path "$worktree")
    [ ! -e "$worktree" ] && [ ! -L "$worktree" ] || fail 'New team worktree path already exists; inspect it instead of creating duplicate work'
    pending=$(mktemp "${TMPDIR:-/tmp}/agent-team-lite-owned.XXXXXX") || fail 'Cannot prepare ownership check'
    trap 'if [ -n "$pending" ]; then rm -f "$pending"; fi; if [ "$mutation_started" = false ] || [ "$operation_complete" = true ]; then rmdir "$control/operation.lock"; fi' EXIT
    printf 'worktree:%s\n' "$worktree" > "$pending"
    for item in "$@"; do
        one_line "$item"
        case "$item" in
            path:*) value=${item#path:}; value=$(canonical_path "$value"); owned_key_for_path "$main" "$value" "$worktree" >> "$pending" ;;
            resource:*) value=${item#resource:}; one_line "$value"; printf 'resource:%s\n' "$value" >> "$pending" ;;
            *) fail 'OWNED entries must be path:ABSOLUTE_PATH or resource:ONE_LINE_ID' ;;
        esac
    done
    sort -u "$pending" -o "$pending"
    assert_disjoint_ownership "$pending"
    mkdir -p "$teams"
    mutation_started=true
    record="$teams/$team.next.$$"
    mkdir "$record" || fail 'Could not prepare team-aware reservation'
    write_at "$record" owner "$owner"
    write_at "$record" task "$task"
    write_at "$record" main "$main"
    write_at "$record" worktree "$worktree"
    write_at "$record" phase planning
    mv "$pending" "$record/owned"
    pending=
    mv "$record" "$teams/$team"
    team_show "$team"
    ;;
team-phase)
    [ "$#" -eq 2 ] || fail 'team-phase TEAM NEXT_PHASE'
    team=$1 next=$2; team_id "$team"; team_owned "$team"
    record="$teams/$team"; current=$(read_team_field "$team" phase)
    case "$current:$next" in
        planning:developing|developing:reviewing|reviewing:developing|reviewing:integrating|integrating:developing|integrating:reviewing|integrating:cleanup) ;;
        planning:paused|developing:paused|reviewing:paused|integrating:paused|cleanup:paused|between:paused|held:paused) write_at "$record" previous "$current" ;;
        *) fail "Unsupported team phase transition: $current -> $next" ;;
    esac
    write_at "$record" phase "$next"
    team_show "$team"
    ;;
team-hold)
    [ "$#" -eq 2 ] || fail 'team-hold TEAM REASON'
    team=$1 reason=$2; team_id "$team"; one_line "$reason"; team_owned "$team"
    record="$teams/$team"; current=$(read_team_field "$team" phase)
    case "$current" in paused|held) fail 'Preserve existing pause/hold; record additional reason in notes' ;; esac
    write_at "$record" held_from "$current"
    write_at "$record" reason "$reason"
    write_at "$record" phase held
    team_show "$team"
    ;;
team-recover)
    [ "$#" -eq 1 ] || fail 'team-recover TEAM'
    team=$1; team_id "$team"; team_owned "$team"
    record="$teams/$team"; [ "$(read_team_field "$team" phase)" = held ] || fail 'Recovery requires held phase'
    prior=$(read_team_field "$team" held_from)
    case "$prior" in planning|developing|reviewing|integrating|cleanup|between) ;; *) fail 'Invalid held phase' ;; esac
    write_at "$record" phase "$prior"
    team_show "$team"
    ;;
team-adopt)
    [ "$#" -eq 2 ] || fail 'team-adopt TEAM NEW_OWNER (optional audit provenance update)'
    team=$1 owner=$2; team_id "$team"; one_line "$owner"; team_owned "$team"
    write_at "$teams/$team" owner "$owner"
    team_show "$team"
    ;;
team-closeout)
    [ "$#" -eq 6 ] || fail 'team-closeout TEAM FULL_INTEGRATED_COMMIT TARGET AUTHORITY RECEIPT disabled|succeeded'
    team=$1 commit=$2 target=$3 authority=$4 receipt=$5 outcome=$6
    team_id "$team"; team_owned "$team"
    record="$teams/$team"
    [ "$(read_team_field "$team" phase)" = between ] || fail 'Closeout requires a retained between phase'
    [ -f "$record/integrated" ] || fail 'Closeout requires a recorded integrated revision'
    [ "$(cat "$record/integrated")" = "$commit" ] || fail 'Closeout commit must equal the recorded integrated revision'
    case "$commit" in ''|*[!0-9a-fA-F]*) fail 'Pass the recorded full hexadecimal integrated commit ID' ;; esac
    [ "${#commit}" -ge 40 ] || fail 'Full integrated commit ID is required'
    one_line "$target"; one_line "$authority"; one_line "$receipt"
    case "$outcome" in
        disabled) [ "$target" = disabled ] && [ "$authority" = disabled ] && [ "$receipt" = disabled ] || fail 'Disabled closeout requires disabled target, authority, and receipt placeholders' ;;
        succeeded) [ "$target" != disabled ] && [ "$authority" != disabled ] && [ "$receipt" != disabled ] || fail 'Succeeded closeout requires exact non-disabled target, authority, and receipt' ;;
        *) fail 'Only disabled or succeeded closeout outcomes can release capacity; hold unknown or failed deployment evidence' ;;
    esac
    write_at "$record" deploy_commit "$commit"
    write_at "$record" deploy_target "$target"
    write_at "$record" deploy_authority "$authority"
    write_at "$record" deploy_receipt "$receipt"
    write_at "$record" deploy_outcome "$outcome"
    team_show "$team"
    ;;
team-finish)
    [ "$#" -eq 2 ] || [ "$#" -eq 3 ] || fail 'team-finish TEAM RECORDED_INTEGRATED_COMMIT [retain]'
    team=$1 commit=$2 mode=${3:-release}; team_id "$team"; team_owned "$team"
    case "$mode" in retain|release) ;; *) fail 'Expected retain or no third argument' ;; esac
    record="$teams/$team"
    [ ! -e "$integration" ] || fail 'Integration remains reserved or uncertain; preserve capacity until its safe endpoint is recorded'
    phase=$(read_team_field "$team" phase)
    case "$phase" in cleanup|between) ;; *) fail 'Finish requires cleanup or between phase after integration' ;; esac
    feature=$(read_team_field "$team" worktree)
    [ ! -e "$feature" ] && [ ! -L "$feature" ] || fail 'Feature worktree still exists; team remains reserved'
    if git worktree list --porcelain | grep -F -x -e "worktree $feature" >/dev/null; then fail 'Feature worktree is still registered; team remains reserved'; fi
    case "$commit" in ''|*[!0-9a-fA-F]*) fail 'Pass the recorded full hexadecimal integrated commit ID' ;; esac
    [ "${#commit}" -ge 40 ] || fail 'Full integrated commit ID is required'
    main=$(read_team_field "$team" main)
    integrated=$(git -C "$main" rev-parse --verify "$commit^{commit}") || fail 'Invalid integration revision'
    git -C "$main" merge-base --is-ancestor "$integrated" HEAD || fail 'Recorded integration revision is not present in the primary checkout'
    if [ "$mode" = retain ]; then
        write_at "$record" integrated "$integrated"
        write_at "$record" phase between
        team_show "$team"
    else
        [ "$phase" = between ] || fail 'Release requires retained between phase and deployment closeout'
        [ -f "$record/integrated" ] && [ "$(cat "$record/integrated")" = "$integrated" ] || fail 'Release revision differs from the retained integrated revision'
        for field in deploy_commit deploy_target deploy_authority deploy_receipt deploy_outcome; do [ -f "$record/$field" ] || fail 'Release requires a complete team-closeout receipt'; done
        [ "$(cat "$record/deploy_commit")" = "$integrated" ] || fail 'Closeout revision differs from the integrated revision'
        case "$(cat "$record/deploy_outcome")" in disabled|succeeded) ;; *) fail 'Closeout outcome cannot release capacity' ;; esac
        write_at "$record" phase complete
        archive="$control/completed-team-$team-$(date +%s)-$$"
        [ ! -e "$archive" ] || fail 'Completion archive collision; preserve state'
        mv "$record" "$archive"
        printf 'Team completed; reservation released. Receipt: %s\n' "$archive"
    fi
    ;;
integration)
    [ "$#" -eq 2 ] || fail 'integration acquire|release TEAM'
    mode=$1 team=$2; team_id "$team"
    case "$mode" in
        acquire)
            team_owned "$team"
            [ "$(read_team_field "$team" phase)" = integrating ] || fail 'Integration acquire requires the team integrating phase'
            [ ! -e "$integration" ] || fail 'Integration is already reserved or its state is incomplete; inspect before continuing'
            mutation_started=true
            mkdir "$integration" || fail 'Could not reserve integration'
            write_at "$integration" team "$team"
            printf 'Integration reserved for team %s.\n' "$team"
            ;;
        release)
            [ -d "$integration" ] && [ -f "$integration/team" ] || fail 'Integration reservation is incomplete or absent; preserve it and inspect'
            [ "$(cat "$integration/team")" = "$team" ] || fail 'Integration is reserved for a different team'
            team_owned "$team"
            case "$(read_team_field "$team" phase)" in cleanup|between|held) ;; *) fail 'Integration release requires a recorded safe endpoint phase' ;; esac
            mutation_started=true
            rm "$integration/team"
            rmdir "$integration" || fail 'Could not release integration reservation'
            printf 'Integration released for team %s.\n' "$team"
            ;;
        *) fail 'integration acquire|release TEAM' ;;
    esac
    ;;
esac

operation_complete=true
