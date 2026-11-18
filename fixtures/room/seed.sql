-- seed.sql — prepopulation data for the Room `notes` table.
-- Generated to match fixtures/sample-data/notes.json exactly (same ids, userIds, titles).
-- Table shape assumed (see fixtures/room/README.md):
--   notes(id INTEGER PRIMARY KEY, userId INTEGER NOT NULL, title TEXT NOT NULL,
--         body TEXT NOT NULL, tags TEXT NOT NULL, pinned INTEGER NOT NULL,
--         createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL)
-- tags is stored as a comma-joined string in this fixture; use a TypeConverter in real code if you prefer.
BEGIN TRANSACTION;
DELETE FROM notes;
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (1, 1, 'Compose state checklist', 'Hoist state, use rememberSaveable for config changes, collect StateFlow with lifecycle.', 'compose,android', 1, '2026-10-01T09:00:00Z', '2026-10-01T09:00:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (2, 1, 'Room migration notes', 'Export schemas, write a migration test for every version bump.', 'room,data', 0, '2026-10-03T10:30:00Z', '2026-10-03T10:30:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (3, 2, 'Release day runbook', 'Build AAB, run internal track, watch vitals for 24h before rollout.', 'release,play', 1, '2026-10-05T08:15:00Z', '2026-10-05T08:15:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (4, 3, 'Game loop timing', 'Clamp dt to 33ms max so physics never explodes after a hitch.', 'games,performance', 0, '2026-10-07T14:20:00Z', '2026-10-07T14:20:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (5, 4, 'Navigation patterns', 'Type-safe routes, one back stack owner, deep links tested from adb.', 'navigation', 0, '2026-10-09T11:45:00Z', '2026-10-09T11:45:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (6, 5, 'Apollo checklist (sample)', 'A fictional checklist used only as sample data for tests.', 'sample', 0, '2026-10-11T16:00:00Z', '2026-10-11T16:00:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (7, 6, 'Coroutines traps', 'Never GlobalScope. structured concurrency, supervisor only where failure is isolated.', 'coroutines', 1, '2026-10-13T09:30:00Z', '2026-10-13T09:30:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (8, 7, 'Accessibility pass', '48dp targets, content descriptions, test with TalkBack and font scale 1.3.', 'accessibility', 0, '2026-10-15T13:10:00Z', '2026-10-15T13:10:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (9, 8, 'Offline-first design', 'Room is source of truth, network only refreshes it.', 'architecture', 0, '2026-10-18T10:00:00Z', '2026-10-18T10:00:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (10, 9, 'Baseline profile results', 'Regenerate after big Compose changes, measure with Macrobenchmark.', 'performance', 0, '2026-10-21T15:40:00Z', '2026-10-21T15:40:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (11, 10, 'Network security config', 'HTTPS only, pin only with a backup pin and an expiry plan.', 'security', 0, '2026-10-24T12:25:00Z', '2026-10-24T12:25:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (12, 11, 'Kernel-style code review', 'Small diffs, clear messages, no unrelated refactoring.', 'process', 0, '2026-10-27T09:05:00Z', '2026-10-27T09:05:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (13, 12, 'Chip design trivia', 'Sample note with no real-world use beyond fixtures.', 'sample', 0, '2026-10-29T17:30:00Z', '2026-10-29T17:30:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (14, 1, 'Play data safety draft', 'List every data type collected, why, and whether it is shared.', 'play,privacy', 0, '2026-11-01T10:10:00Z', '2026-11-01T10:10:00Z');
INSERT INTO notes (id, userId, title, body, tags, pinned, createdAt, updatedAt) VALUES (15, 3, 'Sprite batching idea', 'Draw all balls in one Canvas pass, keep state outside the draw scope.', 'games,compose', 1, '2026-11-03T14:55:00Z', '2026-11-03T14:55:00Z');
COMMIT;
