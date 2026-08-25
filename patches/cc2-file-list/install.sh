#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# shellcheck source=metadata.env
source "$SCRIPT_DIR/metadata.env"
# shellcheck source=sha256.env
source "$SCRIPT_DIR/sha256.env"

CONFIRMED=0
FORCE=0
RESTORE=0
RESTORE_PATH=""
APP_DIR="$DEFAULT_APP_DIR"
POSITIONAL_ARGS=()

while (( $# > 0 )); do
    case "$1" in
        --confirmed)
            CONFIRMED=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --restore)
            RESTORE=1
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage:
  ./install.sh [$DEFAULT_APP_DIR] [--force]
  ./install.sh [$DEFAULT_APP_DIR] --restore [backup-path]

Examples:
  ./install.sh
  ./install.sh /opt/elegoo-slicer
  ./install.sh --force
  ./install.sh --restore
EOF
            exit 0
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if (( ${#POSITIONAL_ARGS[@]} > 0 )); then
    APP_DIR="${POSITIONAL_ARGS[0]}"
fi

if (( RESTORE == 1 && ${#POSITIONAL_ARGS[@]} > 1 )); then
    RESTORE_PATH="${POSITIONAL_ARGS[1]}"
fi

TARGET="$APP_DIR/$TARGET_RELATIVE_PATH"
PATCHER="$SCRIPT_DIR/patcher.py"
BACKUP_PREFIX="$TARGET.backup-$PATCH_ID-"

show_disclaimer() {
    cat <<EOF
===============================================================================
  $PATCH_NAME
  Project: $REPOSITORY_URL
===============================================================================

DISCLAIMER

This is an UNOFFICIAL modification. It directly changes an internal
ElegooSlicer / ElegooLink resource:

  $TARGET

This patch was prepared for a specific known target file and is NOT guaranteed
to work on other builds, package layouts or future ElegooSlicer releases.

Use this software entirely at your own risk. The author and contributors
accept no responsibility for ElegooSlicer or ElegooLink malfunctions, failed
prints, loss of data, hardware problems, or any other direct or indirect issue
that may result from applying this modification.

Compatibility is checked using the SHA256 of the target file. If the checksum
is unknown, installation is refused unless --force is used.

An ElegooSlicer update, reinstall or repair may restore the original file.
If that happens, the patch must be applied again. A future ElegooSlicer build
may also make this patch incompatible.

The installer creates a timestamped backup before replacing the file.

Restore:
  ./install.sh $APP_DIR --restore
  ./install.sh $APP_DIR --restore /full/path/to/backup

This project is not affiliated with or supported by ELEGOO.
===============================================================================
EOF
}

find_latest_backup() {
    local latest_backup=""
    shopt -s nullglob
    local backups=("${BACKUP_PREFIX}"*)
    shopt -u nullglob

    if (( ${#backups[@]} == 0 )); then
        return 1
    fi

    latest_backup="$(ls -1t "${backups[@]}" | head -n 1)"
    printf '%s\n' "$latest_backup"
}

restore_backup() {
    local backup_path="$RESTORE_PATH"

    if [[ -z "$backup_path" ]]; then
        if ! backup_path="$(find_latest_backup)"; then
            echo "Error: no backup found for this patch under: $BACKUP_PREFIX*" >&2
            exit 1
        fi
    fi

    if [[ ! -f "$backup_path" ]]; then
        echo "Error: backup file not found: $backup_path" >&2
        exit 1
    fi

    echo
    echo "Restore source : $backup_path"
    echo "Restore target : $TARGET"

    if (( EUID != 0 )); then
        echo "Root privileges are required to restore the default installation."
        echo "Requesting sudo..."
        SUDO_ARGS=("$SCRIPT_PATH" "--confirmed" "$APP_DIR" "--restore" "$backup_path")
        exec sudo -- "${SUDO_ARGS[@]}"
    fi

    local backup_sha
    local final_sha
    backup_sha="$(sha256sum "$backup_path" | awk '{print $1}')"
    cp -a -- "$backup_path" "$TARGET"
    final_sha="$(sha256sum "$TARGET" | awk '{print $1}')"

    if [[ "$final_sha" != "$backup_sha" ]]; then
        echo "Error: restored file checksum does not match the selected backup." >&2
        exit 1
    fi

    rm -f -- "$backup_path"

    echo
    echo "Restore completed successfully."
    echo "Restored SHA256: $final_sha"
    echo "Deleted backup: $backup_path"
    exit 0
}

show_disclaimer

if [[ ! -f "$TARGET" ]]; then
    echo "Error: target file not found: $TARGET" >&2
    exit 1
fi

if (( RESTORE == 0 )) && [[ ! -f "$PATCHER" ]]; then
    echo "Error: patcher not found: $PATCHER" >&2
    exit 1
fi

for command in python3 sha256sum mktemp cp awk ls head; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command not found: $command" >&2
        exit 1
    fi
done

if (( RESTORE == 1 )); then
    restore_backup
fi

CURRENT_SHA="$(sha256sum "$TARGET" | awk '{print $1}')"
STATE="$("$SCRIPT_DIR/detect.sh" "$TARGET")"

is_known_patched_sha() {
    local sha="$1"
    local known_sha
    for known_sha in "${KNOWN_PATCHED_SHA256[@]}"; do
        if [[ "$sha" == "$known_sha" ]]; then
            return 0
        fi
    done
    return 1
}

echo
echo "Detected state : $STATE"
echo "Target SHA256  : $CURRENT_SHA"

case "$STATE" in
    already_patched)
        echo "Patch already installed. No changes were made."
        exit 0
        ;;
    original)
        ;;
    unknown)
        if (( FORCE == 0 )); then
            echo "Error: target checksum is unknown for this patch." >&2
            echo "Use --force to attempt the patch anyway." >&2
            exit 1
        fi
        echo "Warning: forcing installation on an unknown target checksum."
        ;;
    *)
        echo "Error: unknown detection state: $STATE" >&2
        exit 1
        ;;
esac

if (( CONFIRMED == 0 )); then
    echo
    read -r -p 'Type "I ACCEPT" to continue: ' ANSWER || true
    if [[ "${ANSWER:-}" != "I ACCEPT" ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

if (( EUID != 0 )); then
    echo "Root privileges are required to modify the default installation."
    echo "Requesting sudo..."
    SUDO_ARGS=("$SCRIPT_PATH" "--confirmed" "$APP_DIR")
    if (( FORCE == 1 )); then
        SUDO_ARGS+=("--force")
    fi
    exec sudo -- "${SUDO_ARGS[@]}"
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET.backup-$PATCH_ID-$STAMP"
TMP="$(mktemp "${TARGET}.cc2-file-list.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

cp -a -- "$TARGET" "$BACKUP"
echo "Backup created: $BACKUP"

python3 "$PATCHER" "$TARGET" "$TMP"

GENERATED_SHA="$(sha256sum "$TMP" | awk '{print $1}')"
if ! is_known_patched_sha "$GENERATED_SHA"; then
    echo "Error: generated file checksum does not match the tested patch." >&2
    echo "Expected one of: ${KNOWN_PATCHED_SHA256[*]}" >&2
    echo "Generated: $GENERATED_SHA" >&2
    echo "The installed file was not changed." >&2
    exit 1
fi

cat -- "$TMP" > "$TARGET"

FINAL_SHA="$(sha256sum "$TARGET" | awk '{print $1}')"
if ! is_known_patched_sha "$FINAL_SHA"; then
    echo "Error while writing the patched file. Restoring backup..." >&2
    cp -a -- "$BACKUP" "$TARGET"
    exit 1
fi

echo
echo "Patch installed successfully."
echo "Restart ElegooSlicer if it is currently running."
echo "Backup kept at: $BACKUP"
echo "Restore later with: ./install.sh $APP_DIR --restore $BACKUP"
