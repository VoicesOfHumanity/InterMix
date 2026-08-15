#!/bin/bash
#
# Push the nightly backup off the machine, to a Hetzner Storage Box. RUNS AS ROOT,
# from root's crontab, after script/db_backup.sh has written the local dump.
#
# db_backup.sh protects against a dropped table or a bad migration. This protects
# against losing the host, which is the only scenario the on-box copy cannot help
# with.
#
# WHAT GOES:
#   - the rotated SQL dumps          (/var/backups/intermix/db)
#   - public/images/data             (~66 MB of user-uploaded photos; NOT in git,
#                                     and not reconstructible from anything else)
#   - the three linked config files  (database.yml, localsettings.rb, master.key --
#                                     none of them are in the repo, and losing
#                                     master.key means losing the encrypted
#                                     credentials with it)
#
# DELIBERATELY PLAIN rsync of plain .sql.gz files, not Borg. Borg would dedupe
# and encrypt, and would store these far more efficiently -- but a Borg repo needs
# Borg and a passphrase to read, and if the passphrase is lost the backup is
# worthless. These files can be restored by anyone with the Storage Box password
# and `gunzip`. For a site one person maintains on someone else's behalf, being
# restorable by a stranger is worth more than being small.
#
# The trade-off that buys: the dump is NOT encrypted at rest on the Storage Box.
# It contains participant email addresses and bcrypt password hashes. The Storage
# Box is private and key-authenticated; if that is not judged good enough, switch
# to Borg or pipe through age/gpg before upload.
#
# Hetzner Storage Box notes:
#   - SSH/rsync is on PORT 23, not 22.
#   - Install the key with:  ssh-copy-id -s -p 23 -i <key> <user>@<user>.your-storagebox.de
#     (-s uses the SFTP protocol, which is how Storage Boxes accept keys)
#   - Prefer a SUB-ACCOUNT scoped to its own directory over the main account, so
#     this server's key cannot read or delete anything else stored there.
set -euo pipefail

APP_ROOT=${APP_ROOT:-/home/apps/intermix}
LOCAL_DB=${LOCAL_DB:-/var/backups/intermix/db}
KEY=${KEY:-/root/.ssh/id_ed25519_storagebox}
PORT=${PORT:-23}

# Set these two in /etc/intermix-offsite.conf (root-only, mode 600):
#   SB_USER=u123456
#   SB_HOST=u123456.your-storagebox.de
CONF=${CONF:-/etc/intermix-offsite.conf}
[ -r "$CONF" ] || { echo "$(date -u +%FT%TZ) FAILED: $CONF missing"; exit 1; }
# shellcheck source=/dev/null
. "$CONF"
: "${SB_USER:?SB_USER not set in $CONF}"
: "${SB_HOST:?SB_HOST not set in $CONF}"

[ "$(id -u)" = "0" ] || { echo "$(date -u +%FT%TZ) FAILED: must run as root"; exit 1; }

RSH="ssh -p $PORT -i $KEY -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
REMOTE="$SB_USER@$SB_HOST"

echo "$(date -u +%FT%TZ) starting offsite sync to $SB_HOST"

# Refuse to run if the local backup is stale -- otherwise a silently broken
# db_backup.sh would just keep re-uploading last week's dump, and the offsite
# copy would look healthy while going quietly out of date.
NEWEST=$(find "$LOCAL_DB/daily" -name '*.sql.gz' -mtime -2 | head -1 || true)
[ -n "$NEWEST" ] || { echo "$(date -u +%FT%TZ) FAILED: no local dump newer than 2 days in $LOCAL_DB/daily"; exit 1; }

# Staging dir for the things that are not already a single file.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
tar czf "$STAGE/config.tar.gz" -C "$APP_ROOT/shared" config
chmod 600 "$STAGE/config.tar.gz"

sync_one() {  # sync_one <local path> <remote subdir>
  echo "$(date -u +%FT%TZ)   -> $2"
  rsync -a --delete-after --partial --timeout=1800 \
        -e "$RSH" "$1" "$REMOTE:intermix/$2/"
}

$RSH "$REMOTE" "mkdir -p intermix/db intermix/files intermix/config" 2>/dev/null || true

sync_one "$LOCAL_DB/"                              "db"
sync_one "$APP_ROOT/shared/public/images/data/"    "files"
sync_one "$STAGE/config.tar.gz"                    "config"

echo "$(date -u +%FT%TZ) offsite sync complete"
$RSH "$REMOTE" "du -sh intermix 2>/dev/null" || true
