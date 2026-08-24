# Patch payloads

These files contain the exact plain-text replacement regions inserted into ElegooSlicer's bundled `index.html`.

They are intentionally not Base64-encoded. This keeps the patch inspectable in Git and makes changes reviewable.

Files:

- `get-file-list.js` — preserves additional metadata returned by ElegooLink.
- `file-list-mapping.js` — maps metadata into rows, extracts nozzle diameter and filament type.
- `print-file-list-component.js` — modified file-table component and formatting logic.
- `file-list.css` — small layout override that lets the table use the full available width.

The JavaScript payloads remain minified because ElegooSlicer v1.5.3.4 ships this frontend as a minified bundle. `patcher.py` limits replacements to known markers and the installer checks both original and final SHA256 hashes.
