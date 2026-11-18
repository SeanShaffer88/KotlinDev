# Security and Privacy Checklist

Run before first release and whenever data handling changes.
Detail: [`../docs/15-permissions-security-and-privacy.md`](../docs/15-permissions-security-and-privacy.md).

## Secrets and keys

- [ ] No API keys, passwords, tokens, keystores, or service-account
      files in the repo or the git history (`AGENTS.md` rule 9).
- [ ] Client-embedded keys (where unavoidable) are restricted in
      their provider console (package name + signing SHA) and treated
      as public; anything truly secret lives on a server.
- [ ] Upload key stored in a password manager / secret store with a
      backup owner; Play App Signing recovery path understood.

## Data protection

- [ ] Sensitive data encrypted at rest (EncryptedFile / Keystore-backed
      keys); tokens never in plain SharedPreferences/DataStore.
- [ ] All network traffic is HTTPS; network security config forbids
      cleartext (no `cleartextTrafficPermitted` exceptions without a
      written reason); certificate pinning considered for first-party
      APIs with a rotation plan.
- [ ] WebViews (if any): JavaScript interfaces minimal, file access
      off, only trusted content loaded.
- [ ] Logs contain no personal data, tokens, or request bodies with
      user content — in release builds especially.
- [ ] Backups: `dataExtractionRules` / backup rules exclude tokens and
      sensitive files deliberately, not by accident.

## Permissions and privacy behavior

- [ ] Manifest declares the minimum permissions; every dangerous
      permission is requested in context with a rationale
      ([`../reference/permissions-table.md`](../reference/permissions-table.md)).
- [ ] No permission is used for a purpose different from the one
      shown to the user; background location / special permissions
      only where the feature truly qualifies.
- [ ] Data safety answers match the build: audit analytics/ads SDKs'
      actual collection before answering "no data shared".
- [ ] Privacy policy covers what the app actually does today; consent
      flows (where required) gate the SDKs they describe.
- [ ] User data controls work: export/delete where promised; account
      deletion path tested end to end.

## Platform hardening

- [ ] Components (`exported`) audited: nothing exported without a
      reason; deep links verified (app links with assetlinks.json)
      where claimed.
- [ ] PendingIntents use explicit mutability flags; no implicit
      intent carries sensitive data.
- [ ] Release build: `debuggable=false`, R8 on, no test activities
      or debug receivers reachable.
