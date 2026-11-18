# Fastlane Templates — Play Publishing with `supply`

[fastlane](https://fastlane.tools/) automates the boring half of a
Play release: building the AAB, uploading it to a track, and pushing
the store listing text from files in git. Its Play action is called
**supply**.

## Files here

| File | Copy to | Purpose |
|---|---|---|
| `Appfile.example` | `fastlane/Appfile` | Package name, service-account key path, default track |
| `Fastfile.example` | `fastlane/Fastfile` | Lanes: `build_aab`, `internal`, `promote` |
| `metadata/en-US/*.txt` | stays in place | Store listing text supply uploads (title ≤ 30 chars, short description ≤ 80, full description ≤ 4000) |

Typical layout in a real project:

```text
fastlane/
  Appfile
  Fastfile
  metadata/en-US/title.txt, short_description.txt, full_description.txt
  metadata/<other locales>/...        # one folder per Play language
```

## First-time setup

1. Install fastlane (Ruby gem or the standalone bundle — follow the
   current official install docs; versions move fast).
2. In **Play Console → Users and permissions**, create a service
   account (Google Cloud Console), grant it access to this app only,
   with the release permissions it needs — no more.
3. Download the service-account JSON key. **Treat it like a
   password:** it can publish to your store listing. Keep it outside
   the repo, add it to `.gitignore`, and in CI store it as a secret
   exposed as `SUPPLY_JSON_KEY`. A key committed to git must be
   considered leaked and revoked — see `AGENTS.md` rule 9.
4. Copy the `.example` files, replace `com.example.app`, and replace
   every `REPLACE ME` in the metadata files.
5. First upload of an app must still be done by hand in Play Console
   (supply cannot create an app or its first release). After that:
   `fastlane android internal`.

## Safe habits

- Always land on **internal** (or closed testing) first; promote to
  production as a staged rollout (`promote` lane ships at 20%).
- Metadata in git means listing changes get code review — good.
  Screenshots and feature graphics are not covered by these
  templates; manage them in Play Console or add supply image folders
  deliberately.
- Run fastlane in CI with the key as a secret, and pin the fastlane
  version (Gemfile) so a release is reproducible.
- Verify current fastlane/supply option names against the official
  docs before a real release — this snapshot is from November 2026.
