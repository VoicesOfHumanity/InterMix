#!/bin/bash
#
# Nightly database backup. RUNS AS ROOT, from root's crontab.
#
# Deliberately a shell script and not a rails runner job: a backup you need is
# often a backup taken while the app is broken, so this depends on nothing but
# mysqldump and gzip.
#
# Runs as root so it can authenticate to MariaDB over the unix socket. That means
# no credentials in this file, in the crontab, or in the environment -- and it
# avoids the alternative, which was granting the global RELOAD privilege to the
# application's own database user just so it could take a backup.
#
# Replaces the old IONOS box's /home/ffunch/dbbackup.php, with three changes:
#   - --single-transaction, i.e. NO write lock at all. This used to have to be
#     --lock-all-tables, because half the schema was MyISAM and MyISAM gets no
#     consistent snapshot from a transaction. All 61 tables were converted to
#     InnoDB on 2026-08-15, so the lock-free form is now both correct and free.
#     If a MyISAM table is ever reintroduced, this MUST go back to
#     --lock-all-tables or its rows will be inconsistent in every backup.
#   - --default-character-set=binary --hex-blob, so the dump is a faithful
#     byte-for-byte copy of a mixed latin1/utf8mb3/utf8mb4 schema rather than a
#     re-encode. This is how the 2026-08 migration cloned the database.
#   - Writes to /var/backups, NOT into the deploy tree. The old script wrote to
#     /home/backup on the same box; keeping backups out of /home/apps also means
#     a bad deploy or a capistrano cleanup can never reach them.
#
# ON-BOX ONLY. This protects against a dropped table, a bad migration or a botched
# deploy. It does NOT protect against losing the host -- for that a copy has to
# leave the machine. See doc/migration-2026-08-hetzner.md.
set -euo pipefail

APP_ROOT=${APP_ROOT:-/home/apps/intermix}
CFG="$APP_ROOT/shared/config/database.yml"
DEST=${DEST:-/var/backups/intermix/db}
DAILY_KEEP=${DAILY_KEEP:-7}
WEEKLY_KEEP=${WEEKLY_KEEP:-8}

[ "$(id -u)" = "0" ] || { echo "$(date -u +%FT%TZ) FAILED: must run as root (socket auth)"; exit 1; }

# Only the database NAME is read from database.yml -- no credentials involved.
DB=$(python3 -c "
blk = open('$CFG').read().split('production:')[1]
for line in blk.split(chr(10)):
    s = line.strip()
    if s.startswith('database:'):
        print(s.split(':', 1)[1].strip()); break
")
[ -n "$DB" ] || { echo "$(date -u +%FT%TZ) FAILED: no database name in $CFG"; exit 1; }

mkdir -p "$DEST/daily" "$DEST/weekly"
chmod 700 /var/backups/intermix "$DEST" "$DEST/daily" "$DEST/weekly"
OUT="$DEST/daily/${DB}-$(date -u +%Y-%m-%d).sql.gz"
TMP="$OUT.partial"

echo "$(date -u +%FT%TZ) starting backup of $DB"
# Write to .partial and rename only on success, so an interrupted run can never
# be mistaken for a good backup by the rotation at the bottom.
if ! mysqldump --default-character-set=binary --hex-blob \
      --single-transaction --quick --routines --triggers --events \
      "$DB" 2>/dev/null | gzip -1 > "$TMP"; then
  rm -f "$TMP"; echo "$(date -u +%FT%TZ) FAILED: mysqldump returned non-zero"; exit 1
fi

# A truncated gzip is worse than no backup, because it still looks like one.
if ! gzip -t "$TMP" 2>/dev/null; then
  rm -f "$TMP"; echo "$(date -u +%FT%TZ) FAILED: gzip integrity check failed"; exit 1
fi

SIZE=$(stat -c %s "$TMP")
if [ "$SIZE" -lt 10000000 ]; then   # a real dump here is ~370 MB
  rm -f "$TMP"; echo "$(date -u +%FT%TZ) FAILED: dump only $SIZE bytes, refusing to keep it"; exit 1
fi

mv "$TMP" "$OUT"; chmod 600 "$OUT"
echo "$(date -u +%FT%TZ) wrote $OUT ($(numfmt --to=iec "$SIZE"))"

# Sunday's copy is promoted to the weekly set before daily rotation removes it.
if [ "$(date -u +%u)" = "7" ]; then
  cp -a "$OUT" "$DEST/weekly/${DB}-week-$(date -u +%G-W%V).sql.gz"
  echo "$(date -u +%FT%TZ) promoted to weekly"
fi

# `|| true` on both: with `set -o pipefail`, ls exits non-zero when the glob
# matches nothing (an empty weekly/ dir on any day that is not a Sunday), which
# would otherwise abort the script AFTER a perfectly good backup was written.
ls -1t "$DEST/daily"/${DB}-*.sql.gz       2>/dev/null | tail -n +$((DAILY_KEEP + 1))  | xargs -r rm -f || true
ls -1t "$DEST/weekly"/${DB}-week-*.sql.gz 2>/dev/null | tail -n +$((WEEKLY_KEEP + 1)) | xargs -r rm -f || true

echo "$(date -u +%FT%TZ) done. $(ls -1 "$DEST/daily" | wc -l) daily, $(ls -1 "$DEST/weekly" | wc -l) weekly, $(du -sh "$DEST" | cut -f1) total"
