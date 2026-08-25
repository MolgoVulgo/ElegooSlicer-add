# Patch Format

Each patch directory contains:

- `metadata.env`: patch identity and default target location
- `sha256.env`: known original and patched target checksums
- `detect.sh`: patch-specific state detection
- `patcher.py`: deterministic transformation logic
- `payload/`: inspectable injected or replacement content

Compatibility states:

- `original`: supported original file, patch can be applied
- `already_patched`: the patch is already installed
- `unknown`: the file checksum is not known for this patch

Install behavior:

- default mode accepts only `original`
- `--force` allows `unknown`
- patched output must match the expected patched SHA256
