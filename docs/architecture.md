# Architecture

This repository is organized around installable patches.

## Layout

```text
ElegooSlicer-add/
├── install.sh
├── docs/
└── patches/
    └── <patch-id>/
        ├── README.md
        ├── install.sh
        ├── metadata.env
        ├── sha256.env
        ├── detect.sh
        ├── patcher.py
        └── payload/
```

## Rules

- `install.sh` at the repository root is the main entry point for users.
- Each patch is self-contained under `patches/<patch-id>/`.
- Compatibility is decided by known target-file SHA256 values, not by the reported app version.
- `--force` allows trying a patch on an unknown checksum, but backup and verification remain mandatory.
- A patch may report itself as unnecessary when the upstream file already contains the feature.
