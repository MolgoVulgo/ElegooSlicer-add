# CC2 file list enhancement

Repository: https://github.com/MolgoVulgo/ElegooSlicer-add

This patch improves the file browser shown for a Centauri Carbon 2 through the ElegooLink web interface embedded in ElegooSlicer.

Supported target:

- Linux
- Default application directory: `/opt/elegoo-slicer`
- Default resource file: `/opt/elegoo-slicer/resources/plugins/elegoolink/web/lan_service_web/index.html`

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

The nozzle diameter is not returned by the CC2 file-list command, so this patch extracts it from the file name.

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
cd ElegooSlicer-add
chmod +x install.sh
./install.sh cc2-file-list
```

A custom application directory can be supplied as the second argument:

```bash
./install.sh cc2-file-list /custom/path/to/elegoo-slicer
```

If the target file checksum is unknown, installation is refused by default. Use `--force` only if you explicitly want to try the patch on an unrecognized file:

```bash
./install.sh cc2-file-list --force
```

To restore the most recent backup created by this patch:

```bash
./install.sh cc2-file-list --restore
```

To restore a specific backup file:

```bash
./install.sh cc2-file-list --restore /full/path/to/index.html.backup-cc2-file-list-YYYYMMDD-HHMMSS
```

## Safety behavior

Before modifying anything, the installer:

1. checks that the target `index.html` exists;
2. verifies whether its SHA256 is known for this patch;
3. refuses unknown files unless `--force` is used;
4. creates a timestamped backup;
5. generates the modified file in a temporary file;
6. checks the final SHA256 before replacing the installed file.

If the file is already patched, the installer exits without modifying it.

The restore mode copies a selected backup back to `index.html`, verifies that
the restored checksum matches the backup file, then deletes that backup file.

## Updates

An ElegooSlicer update, reinstall or repair can restore the original `index.html`.
In that case the patch must be applied again.

If ElegooSlicer changes the plugin frontend, the patch may stop applying even if
the visible app version still looks familiar.

## Compatibility model

This patch is gated by the SHA256 of the target file, not by the displayed ElegooSlicer version number.

That means:

- the patch may remain compatible across multiple app versions if the target file is unchanged;
- the patch may be incompatible with another build that reports the same app version;
- forcing installation on an unknown checksum is possible, but intentionally explicit.

## Disclaimer

This project is unofficial and is not affiliated with, endorsed by, or supported by ELEGOO.

All modifications are provided without warranty. They alter internal ElegooSlicer
resources and may stop working after an application update. Use them at your own
risk. The author and contributors are not responsible for application failures,
failed prints, data loss, hardware issues, or other direct or indirect
consequences resulting from their use.
