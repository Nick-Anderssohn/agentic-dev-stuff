#!/usr/bin/env bash
# Install all skills in ./skills/ to ~/.claude/skills/ as symlinks.
# Re-run after adding a new skill. Existing entries are replaced.
#
# Usage:
#   ./install.sh              # symlink every skill in ./skills/
#   ./install.sh <name>...    # symlink only the named skills
#   ./install.sh --copy       # copy files instead of symlinking

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_dir="$repo_root/skills"
dest_dir="$HOME/.claude/skills"

mode="symlink"
names=()
for arg in "$@"; do
    case "$arg" in
        --copy) mode="copy" ;;
        --symlink) mode="symlink" ;;
        -h|--help)
            sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) names+=("$arg") ;;
    esac
done

if [[ ! -d "$src_dir" ]]; then
    echo "error: no skills/ directory at $src_dir" >&2
    exit 1
fi

mkdir -p "$dest_dir"

if [[ ${#names[@]} -eq 0 ]]; then
    shopt -s nullglob
    for path in "$src_dir"/*/; do
        names+=("$(basename "$path")")
    done
    shopt -u nullglob
fi

if [[ ${#names[@]} -eq 0 ]]; then
    echo "no skills found in $src_dir"
    exit 0
fi

for name in "${names[@]}"; do
    skill_src="$src_dir/$name"
    skill_dest="$dest_dir/$name"

    if [[ ! -d "$skill_src" ]]; then
        echo "skip: $name (no directory at $skill_src)" >&2
        continue
    fi

    rm -rf "$skill_dest"

    if [[ "$mode" == "copy" ]]; then
        cp -R "$skill_src" "$skill_dest"
        echo "copied  $name"
    else
        ln -s "$skill_src" "$skill_dest"
        echo "linked  $name -> $skill_src"
    fi
done
