#!/usr/bin/env python3
"""save-migrator.py - example save-game migration tool (v1 -> v2).

Shows the versioned migration-chain pattern to copy into a real game:
each step migrates exactly one version (migrate_1_to_2, ...), a chain
runner applies steps in order, unknown FUTURE versions are refused
(never guess at a newer save's shape), and the original file is kept
as <file>.bak before anything is written.

v1 save: {"version": 1, "player_name": str, "hp": int, "gold": int,
          "level": int, "items": [str, ...]}
v2 save: {"version": 2, "profile": {"name": str},
          "stats": {"health": int, "maxHealth": int, "gold": int,
                    "level": int},
          "inventory": [str, ...], "playSeconds": 0,
          "settings": {"music": true, "sfx": true}}

Changes in 1 -> 2: player_name moves to profile.name; hp becomes
stats.health with a new stats.maxHealth (defaults to health, min 1);
gold/level move under stats; items renamed to inventory; new fields
playSeconds and settings are added with defaults.

Usage: python3 save-migrator.py SAVE.json [--out OUT.json] [--dry-run]
Exit codes: 0 migrated (or already current), 1 bad input,
2 refused (future/unknown version).
"""
import argparse, json, shutil, sys
from pathlib import Path

CURRENT_VERSION = 2


def migrate_1_to_2(save):
    out = {
        "version": 2,
        "profile": {"name": save.get("player_name", "Player")},
        "stats": {
            "health": int(save.get("hp", 1)),
            "maxHealth": max(1, int(save.get("hp", 1))),
            "gold": int(save.get("gold", 0)),
            "level": int(save.get("level", 1)),
        },
        "inventory": list(save.get("items", [])),
        "playSeconds": 0,
        "settings": {"music": True, "sfx": True},
    }
    return out


MIGRATIONS = {1: migrate_1_to_2}  # from-version -> function


def migrate(save):
    """Apply the chain. Returns the migrated dict. Raises ValueError."""
    version = save.get("version")
    if not isinstance(version, int) or isinstance(version, bool):
        raise ValueError("save has no integer 'version' field")
    if version > CURRENT_VERSION:
        raise FutureVersionError(
            f"save version {version} is newer than this tool knows "
            f"(current {CURRENT_VERSION}); refusing to touch it")
    while version < CURRENT_VERSION:
        step = MIGRATIONS.get(version)
        if step is None:
            raise ValueError(f"no migration defined from version {version}")
        save = step(save)
        version = save["version"]
    return save


class FutureVersionError(ValueError):
    pass


def main(argv=None):
    ap = argparse.ArgumentParser(description="Migrate a JSON game save to the current version (v2), keeping a .bak backup.")
    ap.add_argument("save", help="save JSON file to migrate")
    ap.add_argument("--out", default=None, help="write here instead of in place (no .bak is made)")
    ap.add_argument("--dry-run", action="store_true", help="print the migrated save, write nothing")
    args = ap.parse_args(argv)

    p = Path(args.save)
    try:
        save = json.loads(p.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"FAIL: {p} not found", file=sys.stderr); return 1
    except json.JSONDecodeError as e:
        print(f"FAIL: {p} is not valid JSON: {e}", file=sys.stderr); return 1
    if not isinstance(save, dict):
        print("FAIL: save top level is not a JSON object", file=sys.stderr); return 1

    try:
        migrated = migrate(save)
    except FutureVersionError as e:
        print(f"REFUSED: {e}", file=sys.stderr); return 2
    except ValueError as e:
        print(f"FAIL: {e}", file=sys.stderr); return 1

    if migrated.get("version") == save.get("version") and not args.dry_run and not args.out:
        print(f"PASS: {p} is already at version {CURRENT_VERSION}; nothing to do")
        return 0
    text = json.dumps(migrated, indent=2) + "\n"
    if args.dry_run:
        print(text, end="")
        print(f"(dry run: {p} unchanged, would become version {migrated['version']})")
        return 0
    out = Path(args.out) if args.out else p
    if not args.out:
        bak = p.with_suffix(p.suffix + ".bak")
        shutil.copyfile(p, bak)
        print(f"backup: {bak}")
    out.write_text(text, encoding="utf-8")
    print(f"PASS: migrated {p} v{save.get('version')} -> v{migrated['version']} (written to {out})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
