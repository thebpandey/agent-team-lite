#!/bin/sh
# Validate the installable Lite package without installing project dependencies.
set -eu

if [ "$#" -gt 1 ]; then
    echo 'usage: checks/package.sh [package-directory]' >&2
    exit 2
fi
if [ "$#" -eq 0 ]; then
    check_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo 'package check must run inside a Git checkout' >&2
        exit 1
    }
else
    check_root=$1
    [ -d "$check_root" ] || { echo "package directory not found: $check_root" >&2; exit 1; }
fi

for path in SKILL.md LICENSE README.md 'Installation Instructions.md' CHANGELOG.md \
    agents/openai.yaml assets/icon.svg references/commands.md references/hosts.md \
    references/integration.md references/output.md references/runs.md \
    references/state.md scripts/team-slot.sh scripts/readiness.sh; do
    [ -f "$check_root/$path" ] || { echo "missing package file: $path" >&2; exit 1; }
done

# These are repository maintenance files and must never enter an install ZIP.
# The checkout itself necessarily contains them; reject them only when checking
# an extracted/installable package directory.
if [ "$#" -eq 1 ]; then
    for path in checks .github scripts/build-release.sh .git; do
        [ ! -e "$check_root/$path" ] || { echo "repository-only path in package: $path" >&2; exit 1; }
    done
fi

version=$(sed -n 's/^  version: "\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)"$/\1/p' "$check_root/SKILL.md")
[ -n "$version" ] || { echo 'SKILL.md metadata.version is missing or invalid' >&2; exit 1; }
grep -F "**$version**" "$check_root/README.md" >/dev/null || { echo 'README version does not match SKILL.md' >&2; exit 1; }
grep -F "**$version**" "$check_root/Installation Instructions.md" >/dev/null || { echo 'installation version does not match SKILL.md' >&2; exit 1; }
grep -F "## $version" "$check_root/CHANGELOG.md" >/dev/null || { echo 'CHANGELOG has no matching release heading' >&2; exit 1; }

echo "Agent Team Lite package integrity passed (v$version)."
