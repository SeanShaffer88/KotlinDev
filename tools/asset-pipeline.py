#!/usr/bin/env python3
"""asset-pipeline.py - batch image inventory / prep report for games & apps.

Scans an input folder for PNG and JPEG images, reads each image's real
dimensions from its header (stdlib only, no decoding), flags problems,
and writes an inventory (JSON, or CSV with --format csv):

  - textures over 2048 px on either side (mobile GPU / memory risk)
  - non-power-of-two sizes with --npot-warn (older GPUs / mipmapping)
  - unreadable / truncated headers

Resizing: only if Pillow (PIL) is importable. With --resize-max N and
Pillow present, oversized images are written resized to the output
folder; without Pillow the tool says so plainly and only reports.
Without --resize-max the output folder receives just the inventory.

Usage:
    python3 asset-pipeline.py INPUT_DIR [-o OUT_DIR] [--format json|csv]
                              [--npot-warn] [--resize-max 1024]
Exit codes: 0 ok (warnings still exit 0), 1 bad input, 2 unreadable image found.
"""
import argparse, csv, io, json, struct, sys
from pathlib import Path

MAX_TEXTURE = 2048


def png_size(data: bytes):
    if not data.startswith(b"\x89PNG\r\n\x1a\n") or data[12:16] != b"IHDR":
        raise ValueError("bad PNG header")
    w, h = struct.unpack(">II", data[16:24])
    return w, h


def jpeg_size(data: bytes):
    if not data.startswith(b"\xff\xd8"):
        raise ValueError("bad JPEG header")
    pos = 2
    while pos + 4 <= len(data):
        if data[pos] != 0xFF:
            raise ValueError("bad JPEG marker")
        marker = data[pos + 1]
        if marker in (0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
            pos += 2
            continue
        (length,) = struct.unpack(">H", data[pos + 2:pos + 4])
        if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
                      0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
            h, w = struct.unpack(">HH", data[pos + 5:pos + 9])
            return w, h
        pos += 2 + length
    raise ValueError("no JPEG size marker (SOF) found")


def is_pot(n):
    return n > 0 and (n & (n - 1)) == 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Inventory game/app images: dimensions, oversized & NPOT flags, optional Pillow resize.")
    ap.add_argument("input_dir", help="folder of images to scan (recursive)")
    ap.add_argument("-o", "--output", default="asset-report", help="output folder (default asset-report)")
    ap.add_argument("--format", choices=("json", "csv"), default="json", help="inventory format (default json)")
    ap.add_argument("--npot-warn", action="store_true", help="also flag non-power-of-two dimensions")
    ap.add_argument("--resize-max", type=int, default=0, metavar="N",
                    help="with Pillow installed, write copies resized so neither side exceeds N px")
    args = ap.parse_args(argv)

    src = Path(args.input_dir)
    if not src.is_dir():
        print(f"FAIL: {src} is not a folder", file=sys.stderr); return 1
    files = sorted(p for p in src.rglob("*")
                   if p.is_file() and p.suffix.lower() in (".png", ".jpg", ".jpeg"))
    if not files:
        print(f"FAIL: no PNG/JPEG images under {src}", file=sys.stderr); return 1

    pillow = None
    if args.resize_max:
        try:
            from PIL import Image
            pillow = Image
            print(f"Pillow available: oversized images will be resized to fit {args.resize_max}px")
        except ImportError:
            print("Pillow NOT available: resize skipped, report only. "
                  "Install Pillow (python3 -m pip install Pillow) to enable --resize-max.")

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)
    rows, unreadable = [], 0
    for f in files:
        rel = str(f.relative_to(src))
        data = f.read_bytes()
        try:
            w, h = png_size(data) if f.suffix.lower() == ".png" else jpeg_size(data)
        except Exception as e:
            print(f"FAIL: {rel}: unreadable header ({e})")
            unreadable += 1
            rows.append({"file": rel, "width": None, "height": None,
                         "bytes": len(data), "flags": ["unreadable"], "resized": False})
            continue
        flags = []
        if w > MAX_TEXTURE or h > MAX_TEXTURE:
            flags.append(f"oversized (>{MAX_TEXTURE}px)")
        if args.npot_warn and not (is_pot(w) and is_pot(h)):
            flags.append("non-power-of-two")
        resized = False
        if pillow is not None and args.resize_max and (w > args.resize_max or h > args.resize_max):
            dest = out_dir / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            with pillow.open(f) as im:
                im.thumbnail((args.resize_max, args.resize_max))
                im.save(dest)
            resized = True
        rows.append({"file": rel, "width": w, "height": h, "bytes": len(data),
                     "flags": flags, "resized": resized})
        flag_txt = (" [" + "; ".join(flags) + "]") if flags else ""
        print(f"{rel}: {w}x{h}, {len(data)} bytes{flag_txt}" + (" -> resized copy written" if resized else ""))

    inv = out_dir / ("inventory.csv" if args.format == "csv" else "inventory.json")
    if args.format == "csv":
        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=["file", "width", "height", "bytes", "flags", "resized"])
        writer.writeheader()
        for r in rows:
            writer.writerow({**r, "flags": "; ".join(r["flags"])})
        inv.write_text(buf.getvalue(), encoding="utf-8")
    else:
        inv.write_text(json.dumps({"source": str(src), "maxTexture": MAX_TEXTURE,
                                   "images": rows}, indent=2) + "\n", encoding="utf-8")
    warned = sum(1 for r in rows if r["flags"] and r["flags"] != ["unreadable"])
    print(f"PASS: {len(rows)} images inventoried ({warned} flagged, {unreadable} unreadable) -> {inv}")
    return 2 if unreadable else 0


if __name__ == "__main__":
    raise SystemExit(main())
