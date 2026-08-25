#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# shellcheck source=sha256.env
source "$SCRIPT_DIR/sha256.env"

TARGET="${1:?missing target file}"
SHA="$(sha256sum "$TARGET" | awk '{print $1}')"

for known_sha in "${KNOWN_PATCHED_SHA256[@]}"; do
    if [[ "$SHA" == "$known_sha" ]]; then
        echo "already_patched"
        exit 0
    fi
done

for known_sha in "${KNOWN_ORIGINAL_SHA256[@]}"; do
    if [[ "$SHA" == "$known_sha" ]]; then
        echo "original"
        exit 0
    fi
done

echo "unknown"
