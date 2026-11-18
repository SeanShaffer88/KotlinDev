#!/usr/bin/env python3
"""localization-csv.py - Android strings.xml <-> CSV for translators.

Export:  python3 localization-csv.py export app/src/main/res/values/strings.xml strings.csv
Import:  python3 localization-csv.py import strings.csv app/src/main/res/values-es/strings.xml

CSV columns: name, text, translatable, comment
  - `translatable="false"` rows are carried through and marked in the CSV.
  - On import, rows with translatable=false are written back with the
    attribute, and %-format specifiers (%1$s, %d, ...) are preserved
    verbatim (they travel as plain text both ways).
  - String arrays and plurals are NOT handled: export reports them as
    skipped lines, import ignores CSV rows for them. Plain <string>
    entries only - that is the honest scope of a CSV round-trip.

Uses only the standard library (xml.etree.ElementTree + csv).
Exit codes: 0 ok, 1 bad input / parse error.
"""
import argparse, csv, sys
import xml.etree.ElementTree as ET
from pathlib import Path

FIELDS = ["name", "text", "translatable", "comment"]


def do_export(xml_path, csv_path):
    try:
        parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
        tree = ET.parse(xml_path, parser=parser)
    except Exception as e:
        print(f"FAIL: cannot parse {xml_path}: {e}", file=sys.stderr); return 1
    root = tree.getroot()
    if root.tag != "resources":
        print(f"FAIL: {xml_path} root element is <{root.tag}>, expected <resources>", file=sys.stderr)
        return 1
    rows, skipped = [], 0
    pending_comment = ""
    for child in root:
        if child.tag is ET.Comment:
            pending_comment = (child.text or "").strip()
            continue
        if child.tag != "string":
            skipped += 1
            pending_comment = ""
            continue
        rows.append({
            "name": child.get("name", ""),
            "text": "".join(child.itertext()),
            "translatable": child.get("translatable", "true"),
            "comment": pending_comment,
        })
        pending_comment = ""
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    note = f", {skipped} non-string entr(ies) skipped (arrays/plurals are not CSV-friendly)" if skipped else ""
    print(f"PASS: exported {len(rows)} strings -> {csv_path}{note}")
    return 0


def do_import(csv_path, xml_path):
    try:
        with open(csv_path, newline="", encoding="utf-8") as fh:
            rows = list(csv.DictReader(fh))
    except Exception as e:
        print(f"FAIL: cannot read {csv_path}: {e}", file=sys.stderr); return 1
    if not rows or "name" not in (rows[0] or {}):
        print("FAIL: CSV has no 'name' column (expected header: name,text,translatable,comment)",
              file=sys.stderr)
        return 1
    root = ET.Element("resources")
    for row in rows:
        name = (row.get("name") or "").strip()
        if not name:
            continue
        if (row.get("comment") or "").strip():
            root.append(ET.Comment(f" {row['comment'].strip()} "))
        el = ET.SubElement(root, "string", {"name": name})
        if (row.get("translatable") or "true").strip().lower() == "false":
            el.set("translatable", "false")
        el.text = row.get("text") or ""
    ET.indent(root, space="    ")
    out = Path(xml_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(root).write(out, encoding="utf-8", xml_declaration=True)
    print(f"PASS: imported {sum(1 for r in rows if (r.get('name') or '').strip())} strings -> {out}")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Convert Android strings.xml <-> translator CSV (stdlib only).")
    sub = ap.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("export", help="strings.xml -> CSV")
    e.add_argument("xml"); e.add_argument("csv")
    i = sub.add_parser("import", help="CSV -> strings.xml")
    i.add_argument("csv"); i.add_argument("xml")
    args = ap.parse_args(argv)
    if args.cmd == "export":
        return do_export(Path(args.xml), Path(args.csv))
    return do_import(Path(args.csv), Path(args.xml))


if __name__ == "__main__":
    raise SystemExit(main())
