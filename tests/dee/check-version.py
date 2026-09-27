#!/usr/bin/env python3
"""All version fields declared in .version-bump.json must equal 6.4.2."""
import json, re, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
spec = json.loads((root / ".version-bump.json").read_text())
bad = []
for entry in spec["files"]:
    p = root / entry["path"]; field = entry["field"]; text = p.read_text()
    if p.suffix == ".json":
        v = json.loads(text)
        for part in field.split("."):  # e.g. plugins.0.version
            v = v[int(part)] if part.isdigit() else v[part]
    else:  # yaml or toml scalar: `field: "x"` or `field = "x"` or `field: x`
        m = re.search(rf'^\s*{re.escape(field)}\s*[:=]\s*"?([^"\n]+)"?', text, re.M)
        v = m.group(1).strip() if m else None
    if v != "6.4.2":
        bad.append(f"{entry['path']}:{field}={v!r}")
print("version sync: OK" if not bad else "DRIFT: " + ", ".join(bad))
sys.exit(1 if bad else 0)
