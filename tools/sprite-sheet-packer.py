#!/usr/bin/env python3
"""sprite-sheet-packer.py - pack a folder of PNG sprites into one sheet.

Pure Python 3 standard library (zlib + struct). Includes a minimal PNG
decoder/encoder: reads color types 0 (gray), 2 (RGB), 3 (palette),
4 (gray+alpha) and 6 (RGBA) at 8-bit depth (16-bit is reduced to the
high byte; sub-8-bit palette/gray is expanded), and writes a single
RGBA (color type 6) sheet PNG.

Usage:
    python3 sprite-sheet-packer.py INPUT_DIR [-o OUT.png] [--atlas OUT.json]
                                     [--max-width 2048] [--padding 2]

Output atlas JSON: {"sheet": "...", "width": W, "height": H,
"frames": [{"name": "hero.png", "x": 0, "y": 0, "w": 32, "h": 48}, ...]}

Exit codes: 0 ok, 1 bad input / no PNGs, 2 a PNG could not be decoded.
"""
import argparse, json, struct, sys, zlib
from pathlib import Path

PNG_SIG = b"\x89PNG\r\n\x1a\n"


# ---------- minimal PNG codec ----------
def _paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


def decode_png(data: bytes):
    """Return (width, height, rows) where rows = list of bytearray RGBA."""
    if not data.startswith(PNG_SIG):
        raise ValueError("not a PNG file")
    pos = 8
    idat = bytearray()
    plte, trns = [], None
    width = height = bit_depth = color_type = None
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _comp, _filt, interlace = struct.unpack(">IIBBBBB", chunk)
            if interlace:
                raise ValueError("interlaced PNGs are not supported")
        elif ctype == b"PLTE":
            plte = [tuple(chunk[i:i + 3]) for i in range(0, len(chunk), 3)]
        elif ctype == b"tRNS":
            trns = chunk
        elif ctype == b"IDAT":
            idat.extend(chunk)
        elif ctype == b"IEND":
            break
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color_type]
    raw = zlib.decompress(bytes(idat))
    # bytes per pixel for filtering (at least 1)
    if bit_depth >= 8:
        bpp = channels * (bit_depth // 8)
        row_bytes = width * bpp
    else:
        bpp = 1
        row_bytes = (width * channels * bit_depth + 7) // 8
    rows_raw, prev = [], bytearray(row_bytes)
    off = 0
    for _y in range(height):
        ftype = raw[off]; off += 1
        line = bytearray(raw[off:off + row_bytes]); off += row_bytes
        if ftype == 1:
            for i in range(bpp, row_bytes):
                line[i] = (line[i] + line[i - bpp]) & 0xFF
        elif ftype == 2:
            for i in range(row_bytes):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:
            for i in range(row_bytes):
                left = line[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(row_bytes):
                a = line[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + _paeth(a, b, c)) & 0xFF
        elif ftype != 0:
            raise ValueError(f"unknown PNG filter {ftype}")
        rows_raw.append(line)
        prev = line
    # expand to RGBA
    rows = []
    for line in rows_raw:
        out = bytearray(width * 4)
        if bit_depth == 8:
            for x in range(width):
                s = x * channels
                o = x * 4
                if color_type == 6:
                    out[o:o + 4] = line[s:s + 4]
                elif color_type == 2:
                    out[o:o + 3] = line[s:s + 3]; out[o + 3] = 255
                elif color_type == 4:
                    g, a = line[s], line[s + 1]
                    out[o:o + 3] = bytes((g, g, g)); out[o + 3] = a
                elif color_type == 0:
                    g = line[s]
                    out[o:o + 3] = bytes((g, g, g)); out[o + 3] = 255
                elif color_type == 3:
                    idx = line[s]
                    r, g, b = plte[idx]
                    out[o:o + 3] = bytes((r, g, b))
                    out[o + 3] = trns[idx] if trns and idx < len(trns) else 255
        elif bit_depth == 16:
            step = channels * 2
            for x in range(width):
                s = x * step; o = x * 4
                vals = [line[s + i * 2] for i in range(channels)]  # high bytes
                if color_type == 6:
                    out[o:o + 4] = bytes(vals)
                elif color_type == 2:
                    out[o:o + 3] = bytes(vals); out[o + 3] = 255
                elif color_type == 4:
                    out[o:o + 3] = bytes((vals[0],) * 3); out[o + 3] = vals[1]
                elif color_type == 0:
                    out[o:o + 3] = bytes((vals[0],) * 3); out[o + 3] = 255
                else:
                    raise ValueError("16-bit palette PNG is invalid")
        else:  # sub-8-bit gray / palette: unpack samples
            samples = []
            per_byte = 8 // bit_depth
            mask = (1 << bit_depth) - 1
            for byte in line:
                for k in range(per_byte - 1, -1, -1):
                    samples.append((byte >> (k * bit_depth)) & mask)
            maxval = mask
            for x in range(width):
                o = x * 4
                if color_type == 3:
                    idx = samples[x]
                    r, g, b = plte[idx]
                    out[o:o + 3] = bytes((r, g, b))
                    out[o + 3] = trns[idx] if trns and idx < len(trns) else 255
                else:
                    g = samples[x] * 255 // maxval
                    out[o:o + 3] = bytes((g, g, g)); out[o + 3] = 255
        rows.append(out)
    return width, height, rows


def encode_png(width: int, height: int, rows) -> bytes:
    def chunk(ctype, payload):
        c = struct.pack(">I", len(payload)) + ctype + payload
        return c + struct.pack(">I", zlib.crc32(ctype + payload) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (PNG_SIG + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# ---------- packing (simple shelf packer) ----------
def pack(sprites, max_width, padding):
    """sprites: list of (name, w, h, rows). Returns (sheet_w, sheet_h, frames)."""
    order = sorted(sprites, key=lambda s: -s[2])
    frames, x, y, shelf_h = [], 0, 0, 0
    sheet_w = 0
    for name, w, h, _rows in order:
        if w > max_width:
            raise ValueError(f"{name} is {w}px wide, over --max-width {max_width}")
        if x + w > max_width:
            x = 0; y += shelf_h + padding; shelf_h = 0
        frames.append({"name": name, "x": x, "y": y, "w": w, "h": h})
        x += w + padding
        shelf_h = max(shelf_h, h)
        sheet_w = max(sheet_w, x - padding)
    return sheet_w, y + shelf_h, frames


def main(argv=None):
    ap = argparse.ArgumentParser(description="Pack a folder of PNGs into one sprite sheet + JSON atlas (stdlib only).")
    ap.add_argument("input_dir", help="folder containing .png sprites")
    ap.add_argument("-o", "--output", default="sheet.png", help="output sheet PNG (default sheet.png)")
    ap.add_argument("--atlas", default=None, help="output atlas JSON (default: sheet name with .json)")
    ap.add_argument("--max-width", type=int, default=2048, help="maximum sheet width in px (default 2048)")
    ap.add_argument("--padding", type=int, default=2, help="padding between sprites in px (default 2)")
    args = ap.parse_args(argv)

    src = Path(args.input_dir)
    if not src.is_dir():
        print(f"FAIL: {src} is not a folder", file=sys.stderr); return 1
    files = sorted(src.glob("*.png")) + sorted(src.glob("*.PNG"))
    if not files:
        print(f"FAIL: no PNG files in {src}", file=sys.stderr); return 1

    sprites = []
    for f in files:
        try:
            w, h, rows = decode_png(f.read_bytes())
        except Exception as e:
            print(f"FAIL: cannot decode {f.name}: {e}", file=sys.stderr); return 2
        sprites.append((f.name, w, h, rows))

    try:
        sheet_w, sheet_h, frames = pack(sprites, args.max_width, args.padding)
    except ValueError as e:
        print(f"FAIL: {e}", file=sys.stderr); return 1

    canvas = [bytearray(sheet_w * 4) for _ in range(sheet_h)]
    by_name = {s[0]: s for s in sprites}
    for fr in frames:
        _n, w, h, rows = by_name[fr["name"]]
        for row in range(h):
            dst = canvas[fr["y"] + row]
            start = fr["x"] * 4
            dst[start:start + w * 4] = rows[row]

    out_png = Path(args.output)
    out_png.write_bytes(encode_png(sheet_w, sheet_h, canvas))
    out_atlas = Path(args.atlas) if args.atlas else out_png.with_suffix(".json")
    atlas = {"sheet": out_png.name, "width": sheet_w, "height": sheet_h, "frames": frames}
    out_atlas.write_text(json.dumps(atlas, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: packed {len(frames)} sprites -> {out_png} ({sheet_w}x{sheet_h}), atlas {out_atlas}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
