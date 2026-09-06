#!/bin/sh
# Cooperative single-team reservation, shared by all linked Git worktrees.
set -eu
fail() { printf '%s\n' "$*" >&2; exit 1; }
common=$(git rev-parse --git-common-dir) || exit 1
common=$(cd "$common" && pwd -P)
control="$common/agent-team-lite"
slot="$control/slot"
action=${1:-show}
[ "$#" -eq 0 ] || shift
read_field() { cat "$slot/$1"; }
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
case "$action" in claim|phase|resume|adopt|finish|next|hold|recover) ;; *) fail 'Internal actions: show, claim, phase, resume, adopt, finish, next, hold, recover' ;; esac
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
write_field() { mutation_started=true; printf '%s\n' "$2" > "$slot/$1.next"; mv "$slot/$1.next" "$slot/$1"; }
owned() {
    [ -d "$slot" ] || fail 'No reserved team'
    [ -f "$slot/owner" ] && [ -f "$slot/phase" ] || fail 'Incomplete claim: preserve it and inspect before recovery'
    [ "$(read_field owner)" = "$1" ] || fail 'Different owner: confirm old writers stopped before explicit ownership handoff'
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
esac

operation_complete=true
