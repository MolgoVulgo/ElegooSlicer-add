#!/usr/bin/env bash
set -Eeuo pipefail
P="$(readlink -f "$0")";D="$(cd "$(dirname "$P")"&&pwd)";source "$D/metadata.env";C=0;[[ "${1:-}" == --confirmed ]]&&{ C=1;shift; };T="${1:-$DEFAULT_DIR}/index.html"
if ((C==0));then cat <<EOF_D
===============================================================================
$PATCH_NAME — ElegooSlicer $COMPAT_VERSION
$REPOSITORY_URL
===============================================================================
UNOFFICIAL PATCH / NO WARRANTY

This modifies an internal ElegooSlicer / ElegooLink file:
  $T

It is tested only with ElegooSlicer $COMPAT_VERSION on Linux. Use it entirely
at your own risk. The author and contributors accept no responsibility for
application failures, failed prints, data loss, hardware problems, or other
direct or indirect consequences. Updates, reinstalls or repairs may restore the
original file and require this patch to be applied again. Future ElegooSlicer
versions are not guaranteed to remain compatible. A backup and SHA256 checks
are used before installation. This project is not affiliated with ELEGOO.
===============================================================================
EOF_D
read -r -p 'Type "I ACCEPT" to continue: ' A||true;[[ "${A:-}" == "I ACCEPT" ]]||{ echo "Operation cancelled.";exit 0; };fi
((EUID==0))||{ echo "Requesting sudo...";exec sudo -- "$P" --confirmed "$@"; }
for x in python3 sha256sum mktemp cp awk;do command -v "$x">/dev/null||{ echo "Missing command: $x" >&2;exit 1; };done
[[ -f "$T" ]]||{ echo "Target not found: $T" >&2;exit 1; };S="$(sha256sum "$T"|awk '{print $1}')";[[ "$S" == "$PATCHED_SHA256" ]]&&{ echo "Patch already installed. $REPOSITORY_URL";exit 0; };[[ "$S" == "$ORIGINAL_SHA256" ]]||{ echo "Unsupported or modified index.html. Expected ElegooSlicer $COMPAT_VERSION. $REPOSITORY_URL" >&2;exit 1; }
B="$T.backup-$COMPAT_VERSION-$(date +%Y%m%d-%H%M%S)";M="$(mktemp "${T}.cc2-file-list.XXXXXX")";trap 'rm -f "$M"' EXIT;cp -a -- "$T" "$B";python3 "$D/patcher.py" "$T" "$M";N="$(sha256sum "$M"|awk '{print $1}')";[[ "$N" == "$PATCHED_SHA256" ]]||{ echo "Generated checksum mismatch; installed file unchanged." >&2;exit 1; };cat -- "$M">"$T";F="$(sha256sum "$T"|awk '{print $1}')";[[ "$F" == "$PATCHED_SHA256" ]]||{ cp -a -- "$B" "$T";echo "Write verification failed; backup restored." >&2;exit 1; };echo "Installed for ElegooSlicer $COMPAT_VERSION. Backup: $B";echo "Updates may overwrite this patch; future versions are not guaranteed compatible.";echo "$REPOSITORY_URL"
