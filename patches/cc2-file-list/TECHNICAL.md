# Technical notes — CC2 file list

## Data source

For the Centauri Carbon 2, the file-list request is method `1044` (`GET_FILE_LIST`). The relevant response fields include:

```text
filename
size
create_time
layer
print_time
color_map
total_filament_used
total_print_times
last_print_time
type
```

The stock frontend already receives several of these fields but does not display all of them.

This patch exposes the existing metadata to the table instead of issuing one extra detail request per row.

## Nozzle diameter

The CC2 file-list response does not provide nozzle diameter. The patch therefore derives it from the G-code filename with this suffix rule:

```regex
(?:_N|_)(\d+(?:\.\d+)?)\.gcode$
```

Accepted examples:

```text
Part_0.4.gcode
Part_0.6.gcode
Part_N0.8.gcode
```

Only the display label is shortened. The original filename remains stored in the row object and continues to be used by file operations.

## Filament type

ElegooLink's color mapping exposes filament type information. The patch maps each entry to its type and displays unique types joined with ` / ` for multi-material files.

## Print time

`print_time` is already returned by the file-list request. The patch keeps it in the row model and formats seconds as a compact human-readable duration such as:

```text
1h52m
43m08s
52s
```

## Creation date

The original frontend formats creation timestamps with the time of day. This patch intentionally formats only:

```text
YYYY-MM-DD
```

## Patch implementation

ElegooSlicer's bundled frontend is already minified into one large `index.html`. Reformatting the entire vendor bundle would create a huge and fragile diff.

For that reason the patcher replaces three narrowly identified regions and injects one small CSS block. The replacement payloads are stored as plain text under `payload/`; they are not Base64-encoded.

The payload files still look minified because they replace code inside the upstream minified bundle. The installer and patch logic themselves remain readable.

## Integrity checks

Known original `index.html` SHA256:

```text
ca4d84dbd85c0e1da23f94991cdcf1d32a5412b78de4dd17aff79ec53a28e6a3
```

Known patched `index.html` SHA256 values:

```text
c18c722e5b8460696127c5cbc42228868684d3bf261f51a419b8bebefa76093f
```
