#!/usr/bin/env python3
"""tilemap-validate.py - validate a tilemap level JSON file.

Level format (JSON object), two accepted shapes:

Simple shape:
    {
      "name": "level-1",                 // optional
      "width": 20, "height": 15,         // in tiles, required, > 0
      "tileSize": 32,                    // px, required, > 0
      "spawn": {"x": 1, "y": 2},         // player start, tile coords, required
      "entities": [                      // optional list
        {"type": "enemy", "x": 5, "y": 5}, ...
      ],
      "goals": [                         // optional list of points
        {"x": 18, "y": 13}, ...
      ]
    }

Fixtures shape (used by fixtures/sample-data/levels/ in KotlinDev):
    {
      "world": {"widthTiles": 20, "heightTiles": 15, "tileSizePx": 32},
      "playerSpawn": {"xTiles": 1, "yTiles": 2},
      "exit": {"xTiles": 18, "yTiles": 13},   // treated as a goal point
      "entities": [{"type": "coin", "xTiles": 5, "yTiles": 5}, ...],
      "goals": [{"type": "reach-exit", ...}, ...]  // descriptive, not points
    }

Checks: required fields and positive sizes; spawn present, in bounds,
not duplicated by an entity or goal on the same tile; every entity and
goal in bounds (0 <= x < width, 0 <= y < height); no two entities on
the same tile; coordinates are integers.

Usage: python3 tilemap-validate.py LEVEL.json [LEVEL2.json ...]
Exit codes: 0 all valid, 1 validation failed, 2 file/JSON error.
Prints PASS/FAIL per file plus one line per problem found.
"""
import argparse, json, sys
from pathlib import Path


def normalize(level):
    """Map the fixtures shape onto the simple shape (returns a new dict)."""
    if not isinstance(level, dict) or "world" not in level:
        return level
    out = dict(level)
    world = level.get("world") or {}
    out["width"] = world.get("widthTiles")
    out["height"] = world.get("heightTiles")
    out["tileSize"] = world.get("tileSizePx")
    spawn = level.get("playerSpawn") or {}
    out["spawn"] = {"x": spawn.get("xTiles"), "y": spawn.get("yTiles")}

    def remap(pt):
        if not isinstance(pt, dict):
            return pt
        q = dict(pt)
        if "xTiles" in q:
            q["x"] = q.pop("xTiles")
        if "yTiles" in q:
            q["y"] = q.pop("yTiles")
        return q

    out["entities"] = [remap(e) for e in (level.get("entities") or [])]
    goals = []
    for g in level.get("goals") or []:
        if isinstance(g, dict) and ("xTiles" in g or ("x" in g and "y" in g)):
            goals.append(remap(g))
    if isinstance(level.get("exit"), dict):
        goals.append(remap(level["exit"]))
    out["goals"] = goals
    return out


def validate(level):
    problems = []
    if not isinstance(level, dict):
        return ["top level is not a JSON object"]
    level = normalize(level)
    for key in ("width", "height", "tileSize"):
        v = level.get(key)
        if not isinstance(v, int) or isinstance(v, bool) or v <= 0:
            problems.append(f"'{key}' must be a positive integer, got {v!r}")
    if problems:
        return problems
    w, h = level["width"], level["height"]

    def check_point(p, label):
        if not isinstance(p, dict) or "x" not in p or "y" not in p:
            problems.append(f"{label}: must be an object with x and y")
            return None
        x, y = p["x"], p["y"]
        if not isinstance(x, int) or not isinstance(y, int) or isinstance(x, bool) or isinstance(y, bool):
            problems.append(f"{label}: x/y must be integers, got ({x!r}, {y!r})")
            return None
        if not (0 <= x < w and 0 <= y < h):
            problems.append(f"{label}: ({x}, {y}) is out of bounds for a {w}x{h} map")
            return None
        return (x, y)

    spawn = level.get("spawn")
    spawn_xy = None
    if spawn is None:
        problems.append("missing 'spawn' (player start point)")
    else:
        spawn_xy = check_point(spawn, "spawn")

    entity_tiles = {}
    for i, ent in enumerate(level.get("entities", []) or []):
        label = f"entities[{i}]" + (f" ({ent.get('type')})" if isinstance(ent, dict) and ent.get("type") else "")
        xy = check_point(ent, label)
        if xy is None:
            continue
        if xy in entity_tiles:
            problems.append(f"{label}: overlaps {entity_tiles[xy]} on tile {xy}")
        else:
            entity_tiles[xy] = label
        if spawn_xy is not None and xy == spawn_xy:
            problems.append(f"{label}: sits on the spawn tile {xy} (overlapping spawn)")

    for i, goal in enumerate(level.get("goals", []) or []):
        xy = check_point(goal, f"goals[{i}]")
        if xy is not None and spawn_xy is not None and xy == spawn_xy:
            problems.append(f"goals[{i}]: sits on the spawn tile {xy} (overlapping spawn)")
    return problems


def main(argv=None):
    ap = argparse.ArgumentParser(description="Validate tilemap level JSON files (bounds, spawn, overlaps).")
    ap.add_argument("files", nargs="+", help="level JSON file(s) to validate")
    args = ap.parse_args(argv)
    status = 0
    for name in args.files:
        p = Path(name)
        try:
            level = json.loads(p.read_text(encoding="utf-8"))
        except FileNotFoundError:
            print(f"ERROR: {p}: file not found"); status = 2; continue
        except json.JSONDecodeError as e:
            print(f"ERROR: {p}: invalid JSON: {e}"); status = 2; continue
        problems = validate(level)
        if problems:
            print(f"FAIL: {p} ({len(problems)} problem(s))")
            for prob in problems:
                print(f"  - {prob}")
            if status == 0:
                status = 1
        else:
            n = normalize(level)
            print(f"PASS: {p} ({n['width']}x{n['height']} tiles, "
                  f"{len(n.get('entities', []) or [])} entities, "
                  f"{len(n.get('goals', []) or [])} goals)")
    return status


if __name__ == "__main__":
    raise SystemExit(main())
