#!/usr/bin/env python3
"""check-project.py — static validator for an Android project folder.

Usage: python3 check-project.py [project-root]

Checks (Python 3, standard library only):
  * settings.gradle / settings.gradle.kts exists
  * at least one build.gradle / build.gradle.kts exists
  * version catalog gradle/libs.versions.toml present (recommended)
  * AndroidManifest.xml declares an application and a launcher activity
  * build files declare applicationId and targetSdk (warns if missing
    or if targetSdk is below the current Play requirement)
  * no hardcoded API-key-shaped strings in Kotlin / Gradle sources

Prints one PASS / WARN / FAIL line per check and a summary line.
Exit code 0 when there are no FAILs, 1 otherwise.
"""

import os
import re
import sys

# Play requirement mirrored from tools/versions.json (Nov 2026).
TARGET_SDK_REQUIRED = 36

SECRET_PATTERNS = [
    re.compile(r"""(?i)(api[_-]?key|apikey|secret|access[_-]?token)\s*[:=]\s*["'][A-Za-z0-9_\-]{16,}["']"""),
    re.compile(r"""["']AIza[0-9A-Za-z_\-]{20,}["']"""),          # Google API key shape
    re.compile(r"""["']sk-[A-Za-z0-9]{20,}["']"""),               # generic secret-key shape
    re.compile(r"""["']ghp_[A-Za-z0-9]{20,}["']"""),              # GitHub token shape
]

TEXT_EXTS = {".kt", ".kts", ".gradle", ".toml", ".properties", ".xml"}


def find_files(root, names):
    hits = []
    for dirpath, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in {".git", "build", ".gradle"}]
        for f in files:
            if f in names:
                hits.append(os.path.join(dirpath, f))
    return hits


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return ""


def main() -> int:
    root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    fails = warns = 0

    def report(level, msg):
        nonlocal fails, warns
        if level == "FAIL":
            fails += 1
        elif level == "WARN":
            warns += 1
        print(f"{level}: {msg}")

    if not os.path.isdir(root):
        print(f"FAIL: project root not found: {root}")
        return 1

    # 1. Settings file.
    settings = find_files(root, {"settings.gradle", "settings.gradle.kts"})
    if settings:
        report("PASS", f"settings file found: {os.path.relpath(settings[0], root)}")
    else:
        report("FAIL", "no settings.gradle(.kts) — not a Gradle Android project root")

    # 2. Build files.
    builds = find_files(root, {"build.gradle", "build.gradle.kts"})
    if builds:
        report("PASS", f"{len(builds)} build file(s) found")
    else:
        report("FAIL", "no build.gradle(.kts) found")

    build_text = "\n".join(read(p) for p in builds)

    # 3. Version catalog.
    catalog = os.path.join(root, "gradle", "libs.versions.toml")
    if os.path.exists(catalog):
        report("PASS", "version catalog present: gradle/libs.versions.toml")
    else:
        report("WARN", "no gradle/libs.versions.toml — prefer a version catalog "
                       "over scattered dependency versions")

    # 4. Manifest.
    manifests = find_files(root, {"AndroidManifest.xml"})
    if not manifests:
        report("FAIL", "no AndroidManifest.xml found")
    else:
        mtext = "\n".join(read(p) for p in manifests)
        if "<application" in mtext:
            report("PASS", "manifest declares <application>")
        else:
            report("FAIL", "manifest has no <application> element")
        if "android.intent.action.MAIN" in mtext:
            report("PASS", "manifest declares a MAIN launcher intent")
        else:
            report("WARN", "manifest has no MAIN launcher activity "
                           "(fine for libraries, wrong for apps)")

    # 5. applicationId / targetSdk.
    if re.search(r"applicationId\s*[= ]", build_text):
        report("PASS", "applicationId declared in a build file")
    else:
        report("WARN", "no applicationId in build files — apps need a unique "
                       "applicationId (namespace alone is not enough for Play)")

    m = re.search(r"targetSdk\s*[= ]\s*(\d+)", build_text)
    if m:
        sdk = int(m.group(1))
        if sdk >= TARGET_SDK_REQUIRED:
            report("PASS", f"targetSdk {sdk} meets the Play requirement "
                           f"({TARGET_SDK_REQUIRED})")
        else:
            report("WARN", f"targetSdk {sdk} is below the Play requirement "
                           f"({TARGET_SDK_REQUIRED}) for new apps and updates")
    else:
        report("WARN", "no literal targetSdk in build files — if it comes from "
                       "the version catalog, verify it is >= "
                       f"{TARGET_SDK_REQUIRED}")

    # 6. Hardcoded secrets scan.
    hits = []
    for dirpath, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in {".git", "build", ".gradle"}]
        for f in files:
            if os.path.splitext(f)[1] not in TEXT_EXTS:
                continue
            path = os.path.join(dirpath, f)
            for i, line in enumerate(read(path).splitlines(), 1):
                if any(p.search(line) for p in SECRET_PATTERNS):
                    hits.append(f"{os.path.relpath(path, root)}:{i}")
    if hits:
        for h in hits[:10]:
            report("FAIL", f"possible hardcoded API key / secret at {h} — move "
                           "secrets to local.properties, environment variables, "
                           "or a secrets backend; never commit them")
    else:
        report("PASS", "no hardcoded API-key-shaped strings found")

    print(f"\nSummary: {fails} FAIL, {warns} WARN")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
