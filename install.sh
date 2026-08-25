#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"

# shellcheck source=patches/index.sh
source "$PATCHES_DIR/index.sh"

print_usage() {
    cat <<'EOF'
Usage:
  ./install.sh --list
  ./install.sh <patch-id> [app-dir] [--force]
  ./install.sh <patch-id> [app-dir] --restore [backup-path]

Examples:
  ./install.sh --list
  ./install.sh cc2-file-list
  ./install.sh cc2-file-list --force
  ./install.sh cc2-file-list /opt/elegoo-slicer
  ./install.sh cc2-file-list --restore
EOF
}

print_patch_list() {
    echo "Available patches:"
    for patch_id in "${PATCH_INDEX[@]}"; do
        echo "- $patch_id"
    done
}

run_patch() {
    local patch_id="$1"
    shift

    local patch_dir="$PATCHES_DIR/$patch_id"
    local installer="$patch_dir/install.sh"

    if [[ ! -d "$patch_dir" || ! -f "$installer" ]]; then
        echo "Unknown patch: $patch_id" >&2
        exit 1
    fi

    exec "$installer" "$@"
}

case "${1:-}" in
    "" )
        print_patch_list
        echo
        print_usage
        ;;
    --list )
        print_patch_list
        ;;
    --help|-h )
        print_usage
        ;;
    * )
        run_patch "$@"
        ;;
esac
