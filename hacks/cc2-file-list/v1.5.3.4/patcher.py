#!/usr/bin/env python3
"""Apply the CC2 file-list frontend changes to a copy of index.html.

Project: https://github.com/MolgoVulgo/ElegooSlicer-add
Compatibility target: ElegooSlicer v1.5.3.4

The installer performs the SHA256 checks and backup handling. This program only
performs deterministic text replacements using the inspectable payload files in
./payload.
"""

from __future__ import annotations

import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PAYLOAD_DIR = SCRIPT_DIR / "payload"

REGIONS = (
    (
        "ElegooLink getFileList mapping",
        "async getFileList(t,n){return this.withIpcCommandDelivery(Pt.GetFileList,async()=>{var r,i;try",
        "async getFileDetail(t,n){return this.withIpcCommandDelivery",
        "get-file-list.js",
    ),
    (
        "file metadata row mapping",
        'Y=H(()=>{{const De=[];return B.value==="file"||B.value==="printHistory"?',
        "Ke(Y,De=>",
        "file-list-mapping.js",
    ),
    (
        "print-file-list Vue component",
        'RWe=Xe({__name:"print-file-list"',
        ",kWe=Zn(RWe,",
        "print-file-list-component.js",
    ),
)


def read_payload(name: str) -> str:
    path = PAYLOAD_DIR / name
    if not path.is_file():
        raise RuntimeError(f"Missing payload: {path}")
    return path.read_text(encoding="utf-8")


def replace_region(
    text: str,
    label: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
) -> str:
    start = text.find(start_marker)
    if start < 0:
        raise RuntimeError(f"Start marker not found for {label}")

    end = text.find(end_marker, start)
    if end < 0:
        raise RuntimeError(f"End marker not found for {label}")

    # Refuse ambiguous matches. The patch is intended to be surgical.
    if text.find(start_marker, start + 1) >= 0:
        raise RuntimeError(f"Start marker is not unique for {label}")

    return text[:start] + replacement + text[end:]


def patch(source: Path, destination: Path) -> None:
    text = source.read_text(encoding="utf-8")

    for label, start_marker, end_marker, payload_name in REGIONS:
        text = replace_region(
            text,
            label,
            start_marker,
            end_marker,
            read_payload(payload_name),
        )

    css = read_payload("file-list.css").rstrip("\n")
    if 'id="cc2-filelist-v3"' in text:
        raise RuntimeError("CC2 file-list CSS marker already exists")

    head_end = text.find("</head>")
    if head_end < 0:
        raise RuntimeError("</head> marker not found")

    text = text[:head_end] + css + text[head_end:]
    destination.write_text(text, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {Path(sys.argv[0]).name} SOURCE_HTML OUTPUT_HTML", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])

    try:
        patch(source, destination)
    except Exception as exc:
        print(f"Patch failed: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
