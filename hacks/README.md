# Hacks

Each hack is stored under:

```text
hacks/<hack-name>/<supported-version>/
```

The feature directory contains user and technical documentation. The version directory contains the actual installer and patch implementation for one specific ElegooSlicer version.

Rules used by this repository:

- Keep hacks independent from each other.
- Declare exact supported ElegooSlicer versions.
- Verify upstream files by SHA256 before writing.
- Create a backup before modification.
- Do not hide patch payloads in Base64 or similar encoding when avoidable.
- Prefer inspectable source files and narrowly scoped transformations.
- Expect ElegooSlicer updates to overwrite modified resources.
