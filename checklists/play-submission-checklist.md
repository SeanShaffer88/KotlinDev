# Play Submission Checklist

Run in Play Console for each production submission. Requirements
detail: [`../reference/play-requirements-and-deadlines.md`](../reference/play-requirements-and-deadlines.md).

## Policy gates

- [ ] App targets API 36 (required for new apps/updates since
      August 31, 2026); AAB uploaded (not APK).
- [ ] Billing Library 8+ integrated if the app sells digital goods;
      no external payment links for digital goods unless a current
      Play program explicitly allows them.
- [ ] Data safety section completed and accurate against the actual
      build (SDKs included — audit third-party SDK data practices).
- [ ] Privacy policy URL live and matching the data safety answers.
- [ ] Account deletion: in-app path works; web deletion URL declared
      (for apps with account creation).
- [ ] Permissions declarations submitted for every sensitive
      permission / FGS type the build declares
      ([`../reference/permissions-table.md`](../reference/permissions-table.md)).
- [ ] Content rating questionnaire completed; target audience and
      Families answers accurate.
- [ ] Ads declaration accurate (contains ads / no ads); ad SDKs, if
      any, are Families-certified when children are in the audience.

## Store listing

- [ ] Title, short and full descriptions factual; no keyword stuffing,
      no claims the build does not support.
- [ ] Screenshots are real captures of the current build on the
      declared form factors; feature graphic current.
- [ ] Release notes contain only this version's changes, in plain
      language.
- [ ] Contact email and developer details current.

## Rollout

- [ ] Closed/internal testing pass completed first (and the
      12-tester / 14-day closed test satisfied where the account
      requires it — verify current terms in Play Console help).
- [ ] Staged rollout percentage chosen (small first step); halt
      criteria decided before starting.
- [ ] Android vitals watched during rollout (crash/ANR vs bad-behavior
      thresholds); mapping file uploaded/kept for symbolication.
- [ ] Rollback plan known: halt rollout, ship a fixed version code —
      a published version code can never be reused.
