# Tools

Standalone utilities that speed up Android development in Kotlin.
None of them need an emulator or a device.

| Tool | What it does |
|---|---|
| [`new-project.sh`](new-project.sh) / [`new-project.ps1`](new-project.ps1) | Scaffolds a new Compose app from [`../templates/compose-app/`](../templates/compose-app/) into a ready-to-open folder: substitutes the project name and package id, renames the package folders. |
| [`check-project.py`](check-project.py) | Static validator for an Android project folder: settings/build files exist, version catalog present, manifest sanity, `applicationId` / `targetSdk` warnings, hardcoded API-key scan. Python 3, standard library only. |
| [`versions.json`](versions.json) | The verified version snapshot (November 2026) from the docs in machine-readable form — Kotlin, AGP, Gradle, Compose BOM, SDK levels, and the key Jetpack libraries. Re-check before production use; see its `verifyBeforeUse` note. |
| [`ide.md`](ide.md) | Android Studio setup notes: recommended settings, what is bundled vs what to install, and a copy-paste `.editorconfig`. |
| [`build-ai-bundle.py`](build-ai-bundle.py) | Regenerates the repo-root `manifest.json` (machine-readable file map + reading order) and `ai-bundle.md` (the whole knowledge base as one file) so AI tools that download the repo — ChatGPT included — can ingest it locally. Run after any content change. |

Usage examples are in each file's header.
