#!/usr/bin/env bash
set -Eeuo pipefail

# CC2 file list enhancement for ElegooSlicer.
# Project: https://github.com/MolgoVulgo/ElegooSlicer-add
# Compatibility target: ElegooSlicer v1.5.3.4 on Linux.

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck source=metadata.env
source "$SCRIPT_DIR/metadata.env"

CONFIRMED=0
if [[ "${1:-}" == "--confirmed" ]]; then
    CONFIRMED=1
    shift
fi

TARGET_DIR="${1:-$DEFAULT_DIR}"
TARGET="$TARGET_DIR/index.html"
PATCHER="$SCRIPT_DIR/patcher.py"

show_disclaimer() {
    cat <<EOF_DISCLAIMER
===============================================================================
  $PATCH_NAME
  Compatibility: ElegooSlicer $COMPAT_VERSION on Linux
  Project: $REPOSITORY_URL
===============================================================================

DISCLAIMER

This is an UNOFFICIAL modification. It directly changes an internal
ElegooSlicer / ElegooLink resource:

  $TARGET

This patch was built and tested for ElegooSlicer $COMPAT_VERSION only.
Compatibility with any other ElegooSlicer version is NOT guaranteed.

Use this software entirely at your own risk. The author and contributors
accept no responsibility for ElegooSlicer or ElegooLink malfunctions, failed
prints, loss of data, hardware problems, or any other direct or indirect issue
that may result from applying this modification.

An ElegooSlicer update, reinstall or repair may restore the original file.
If that happens, the patch must be applied again. A future ElegooSlicer version
may also make this patch incompatible, and there is no guarantee that the same
procedure will continue to work.

The installer verifies the original SHA256 checksum and creates a timestamped
backup before modifying the file.

This project is not affiliated with or supported by ELEGOO.
===============================================================================
EOF_DISCLAIMER
}

if (( CONFIRMED == 0 )); then
    show_disclaimer
    echo
    read -r -p 'Type "I ACCEPT" to continue: ' ANSWER || true
    if [[ "${ANSWER:-}" != "I ACCEPT" ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

if (( EUID != 0 )); then
    echo "Root privileges are required to modify the default /opt installation."
    echo "Requesting sudo..."
    exec sudo -- "$SCRIPT_PATH" --confirmed "$@"
fi

for command in python3 sha256sum mktemp cp awk; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: required command not found: $command" >&2
        exit 1
    fi
done

if [[ ! -f "$TARGET" ]]; then
    echo "Error: target file not found: $TARGET" >&2
    exit 1
fi

if [[ ! -f "$PATCHER" ]]; then
    echo "Error: patcher not found: $PATCHER" >&2
    exit 1
fi

CURRENT_SHA="$(sha256sum "$TARGET" | awk '{print $1}')"

if [[ "$CURRENT_SHA" == "$PATCHED_SHA256" ]]; then
    echo "Patch already installed. No changes were made."
    echo "Project: $REPOSITORY_URL"
    exit 0
fi

if [[ "$CURRENT_SHA" != "$ORIGINAL_SHA256" ]]; then
    cat >&2 <<EOF_ERROR

ABORTED: index.html does not match the expected ElegooSlicer build.

Supported version : ElegooSlicer $COMPAT_VERSION
Expected SHA256   : $ORIGINAL_SHA256
Detected SHA256   : $CURRENT_SHA

The file may already have been modified or ElegooSlicer may have been updated.
For safety, this installer will not attempt a fuzzy or partial patch.

Check the repository for an updated hack:
$REPOSITORY_URL
EOF_ERROR
    exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET.backup-$COMPAT_VERSION-$STAMP"
TMP="$(mktemp "${TARGET}.cc2-file-list.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

cp -a -- "$TARGET" "$BACKUP"
echo "Backup created: $BACKUP"

python3 "$PATCHER" "$TARGET" "$TMP"

GENERATED_SHA="$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$GENERATED_SHA" != "$PATCHED_SHA256" ]]; then
    echo "Error: generated file checksum does not match the tested patch." >&2
    echo "Expected: $PATCHED_SHA256" >&2
    echo "Generated: $GENERATED_SHA" >&2
    echo "The installed file was not changed." >&2
    exit 1
fi

# Writing into the existing file keeps its owner, mode and filesystem context.
cat -- "$TMP" > "$TARGET"

FINAL_SHA="$(sha256sum "$TARGET" | awk '{print $1}')"
if [[ "$FINAL_SHA" != "$PATCHED_SHA256" ]]; then
    echo "Error while writing the patched file. Restoring backup..." >&2
    cp -a -- "$BACKUP" "$TARGET"
    exit 1
fi

echo
echo "Patch installed successfully for ElegooSlicer $COMPAT_VERSION."
echo "Restart ElegooSlicer if it is currently running."
echo "Backup kept at: $BACKUP"
echo
echo "Reminder: an ElegooSlicer update may restore index.html and require the patch"
echo "to be applied again. Future versions are not guaranteed to be compatible."
echo "Project and updates: $REPOSITORY_URL"
