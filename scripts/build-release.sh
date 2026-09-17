#!/bin/sh
# Build the installable ZIP from one exact committed revision.
set -eu

usage() {
    echo "usage: $0 REVISION [OUTPUT_DIRECTORY]" >&2
    exit 2
}
[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

repo=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo 'release build must run inside a Git checkout' >&2
    exit 1
}
revision=$(git -C "$repo" rev-parse --verify "$1^{commit}") || {
    echo "invalid revision: $1" >&2
    exit 1
}
output_dir=${2:-$repo/dist}
case "$output_dir" in
    /*) ;; *) output_dir=$repo/$output_dir ;;
esac

version=$(git -C "$repo" show "$revision:SKILL.md" | sed -n 's/^  version: "\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)"$/\1/p')
[ -n "$version" ] || { echo "revision $revision has no valid SKILL.md version" >&2; exit 1; }
mkdir -p "$output_dir"
archive="$output_dir/agent-team-lite-$version.zip"
checksum="$output_dir/SHA256SUMS"
revision_record="$output_dir/RELEASE_REVISION"
prefix='agent-team-lite/'
[ ! -e "$archive" ] || { echo "refusing to overwrite existing archive: $archive" >&2; exit 1; }
[ ! -e "$checksum" ] || { echo "refusing to overwrite existing checksums: $checksum" >&2; exit 1; }
[ ! -e "$revision_record" ] || { echo "refusing to overwrite revision evidence: $revision_record" >&2; exit 1; }

# Select tracked install files at the requested revision. This makes the ZIP
# independent of the checkout's dirty state and omits repository-only checks,
# CI configuration, and this maintenance builder. Git pathspecs preserve paths
# containing spaces, such as the installation guide.
git -C "$repo" archive --format=zip --prefix="$prefix" "$revision" -- . \
    ':(exclude)checks' ':(exclude)checks/**' \
    ':(exclude).github' ':(exclude).github/**' \
    ':(exclude)scripts/build-release.sh' >"$archive"
printf '%s  %s\n' "$(sha256sum "$archive" | awk '{print $1}')" "$(basename "$archive")" >"$checksum"
printf '%s\n' "$revision" >"$revision_record"

echo "Built $archive from revision $revision (v$version)."
echo "Wrote $checksum."
