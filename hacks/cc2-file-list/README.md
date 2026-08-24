# CC2 file list enhancement

Repository: https://github.com/MolgoVulgo/ElegooSlicer-add

This hack improves the file browser shown for a Centauri Carbon 2 through the ElegooLink web interface embedded in ElegooSlicer.

Supported build:

- **ElegooSlicer v1.5.3.4**
- Linux
- Default resource directory: `/opt/elegoo-slicer/resources/plugins/elegoolink/web/lan_service_web`

## What changes

The file table is changed to show useful metadata already returned by ElegooLink while keeping the layout readable:

- File Name
- File Size
- Layers
- Nozzle
- Print Time
- Filament
- Creation Time
- Filament Consumption

Additional display rules:

- The table uses the full available width.
- Only the `File Name` column is flexible/resizable.
- Other columns keep fixed widths so their values remain readable.
- Long file names are truncated by the table and remain available through the existing overflow tooltip.
- `Creation Time` is displayed as `YYYY-MM-DD`; the time of day is intentionally omitted.
- The real file name is kept internally for print/export/delete operations.
- The displayed file name omits the nozzle suffix.

## G-code naming convention

The nozzle diameter is not returned by the CC2 file-list command, so this hack extracts it from the file name.

Recommended ElegooSlicer output filename format:

```text
{first_object_name}_{nozzle_diameter[0]}.gcode
```

Example:

```text
SupportMoteur_0.6.gcode
```

The table displays:

```text
File Name: SupportMoteur
Nozzle:    0.6 mm
```

The parser also accepts the explicit form:

```text
SupportMoteur_N0.6.gcode
```

## Installation

```bash
git clone https://github.com/MolgoVulgo/ElegooSlicer-add.git
cd ElegooSlicer-add/hacks/cc2-file-list/v1.5.3.4
chmod +x install.sh
./install.sh
```

The installer asks for explicit confirmation and then requests `sudo` because the default target is under `/opt`.

A custom resource directory can be supplied as the first argument:

```bash
./install.sh /custom/path/to/lan_service_web
```

`install.min.sh` provides the same installer behavior in a compact shell wrapper. Both installers use the same readable `patcher.py` and plain-text payload files.

## Safety behavior

Before modifying anything, the installer:

1. checks that the target `index.html` exists;
2. verifies that its SHA256 matches the original ElegooSlicer v1.5.3.4 file;
3. refuses to patch unknown or modified builds;
4. creates a timestamped backup;
5. generates the modified file in a temporary file;
6. checks the final SHA256 before replacing the installed file.

If the file is already patched, the installer exits without modifying it.

## Updates and compatibility

An ElegooSlicer update, reinstall or repair can restore the original `index.html`. In that case the patch must be applied again.

Do not apply this v1.5.3.4 patch to another ElegooSlicer version unless its compatibility has been explicitly verified. A future version may move, rebuild or redesign the ElegooLink frontend and this patch may no longer apply.
