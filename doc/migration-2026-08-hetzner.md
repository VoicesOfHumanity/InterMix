# Migration: IONOS bare metal → Hetzner Hillsboro

**From:** `198.71.53.140` — IONOS dedicated server, Ubuntu 18.04.4, glibc 2.27, MySQL 5.7,
PHP 5.6, 832 days uptime. EOL since April 2023.
**To:** `5.78.151.159` — Hetzner Cloud CPX21 (`intermix-prod`), Hillsboro `hil-dc1`,
3 vCPU / 3.8 GB / 75 GB, Ubuntu 24.04.4, MariaDB 10.11.

**Status: CUT OVER 2026-08-15 12:53–13:04 UTC. Live on the new server.**

## Why this rather than an in-place upgrade

18.04 cannot be upgraded in place safely (three sequential `do-release-upgrade` steps, a
forced MySQL 5.7→8.0 conversion, PHP 5.6 from a PPA that does not exist past bionic), and
bare metal has no snapshot to roll back to. The old box was also verified to be serving
exactly **one** thing — `intermix.org` and `voh.intermix.org`. Every other vhost on it
resolves elsewhere or has no A record at all.

## What is on the new box

| | |
|---|---|
| Ruby | 3.2.11 via rbenv (`/home/ploy/.rbenv`), bundler pinned 2.4.22 to match the lockfile |
| Web | Apache 2.4.58 + `libapache2-mod-passenger` 6.0.17 — Ubuntu's own packages, no third-party repo |
| DB | MariaDB 10.11.14 (**not** MySQL 8 — see below) |
| App | `/home/apps/intermix`, deploy user `ploy`, same layout as the old box |
| Firewall | ufw: 22, 80, 443 |
| Swap | 2 GB (`/swapfile`), `vm.swappiness=10` |

### Deliberate deviations from the old box

**MariaDB 10.11, not MySQL 8.** `legacy-vps` (staging) already runs MariaDB 10.11 and local
dev runs MariaDB, so this makes production match the environments the app is actually tested
on. It also avoids MySQL 8's `caching_sha2_password` default and its utf8mb3 renaming.

**The DB user was renamed and its password rotated.** The old box's app user was literally
named `mysql`, which collides with the built-in `mysql@localhost` account MariaDB 10.11
ships — granting the app a password on that name would have handed it a root alias. The new
box uses `intmix` with a freshly generated password. Only `shared/config/database.yml`
changed; nothing in the repo refers to the username.

**MariaDB tuned for 3.8 GB** in `/etc/mysql/mariadb.conf.d/60-intermix.cnf`: 512 M InnoDB
buffer pool and 256 M key buffer, because the schema is 30 InnoDB tables *and* 31 MyISAM.

**`PassengerMaxPoolSize 3`.** The default of 6 × ~400 MB workers would OOM a 3.8 GB box
shared with MariaDB. The site has ~10 monthly active users.

**`/etc/gai.conf` prefers IPv4.** See "IPv6" below — this is load-bearing, not cosmetic.

## Two things that bit during the build

**1. IPv6 to the CDNs is broken from this box.** The address, route and gateway are all
correct and `ping6` reaches Cloudflare and Google DNS — but TCP to rubygems.org and
github.com over IPv6 hangs. `curl` survives via Happy Eyeballs; Ruby's `net/http` does not,
so `bundle install` died with "Failed to open TCP connection to rubygems.org:80". Fixed by
appending `precedence ::ffff:0:0/96 100` to `/etc/gai.conf`, which makes `getaddrinfo`
return IPv4 first. **This would also have hung ActivityPub federation**, which makes
outbound HTTPS to arbitrary remote servers. Worth raising with Hetzner support; the
IPv4 preference is a fine permanent setting either way, since the site has no AAAA record.

**2. rbenv must be initialised above the guard in `~/.bashrc`.** Ubuntu's stock `.bashrc`
returns early for non-interactive shells, so anything appended at the end is invisible to
`bash -lc` — which is what Capistrano, cron and scripted checks all use. They would silently
get `/usr/bin/ruby` 3.2.3 instead of rbenv's 3.2.11. The exports now sit at the top of the
file with a comment saying why.

## What has been verified

Database restored with `--default-character-set=binary --hex-blob` — a faithful byte-for-byte
copy, chosen because the schema is mixed (16 latin1, 43 utf8mb3, 2 utf8mb4) and the goal is a
clone, not a re-encode. No routines, triggers or views to trip on.

- **All 61 tables present; 7,950,020 rows on both boxes; per-table counts identical.**
- Deploy succeeds end to end (bundle, nokogiri from source, assets, migrations, restart).
- `BASEDOMAIN` resolves to `voh.intermix.org` — i.e. `production.rb`'s environment detection
  correctly does **not** think this is staging. `INT_CONVERSATION_ID` is the production value.
- HTTP via `--resolve`, no DNS: homepage 200 (correct title, front layout rendering from
  restored data), `/participants/sign_in` 200, webfinger 404 for an unknown account.
- Signed-in: `/communities/new` 200 with the form, `/me/comtag` bare → 400, and
  `passwords#new` from `intermix.org` → 302 to `https://voh.intermix.org/me/profile/meta`
  (all three of the August fixes confirmed live on the new box).
- Both sanitizers strip `script`/`onerror`/`javascript:` and keep legitimate markup.
- Memory under load: 1.4 GB used, 2.4 GB available. Disk 8 GB of 75 GB.

## ⚠️ Cron is deliberately empty

Both `root` and `ploy` have **no crontab** on the new box, and this must stay true until
cutover. There are eight jobs (two ActivityPub workers, `update_system`, `mail_moon`,
`mail_send`, `postmark_bounces`, `follow_mutual`, `cron_watchdog`). If both boxes run them
during the parallel period, real people receive duplicate digest emails and the fediverse
receives duplicate deliveries — and this project has already had one runaway-send incident.

**Enabling cron on the new box and disabling it on the old one is a single atomic step,
paired with the DNS flip.** See step 5.

Remember the SYS_MODE asymmetry from `config/activitypub_crontab.example`: **staging sets
`SYS_MODE=staging`; production must omit it.** Cron does not inherit it from Apache.

## Cutover — done 2026-08-15

Executed 12:53–13:04 UTC, about 11 minutes of downtime. Visitors saw a maintenance
page rather than a connection error, because the new box was switched to a 503
maintenance vhost *before* the old one was stopped — so DNS propagated during the
data copy instead of after it.

Sequence as run: disable old cron (backed up to `~/crontab.backup-cutover-20260815.txt`)
-> stop old Apache -> maintenance vhost up -> DNS flipped at Cloudflare -> final dump
with `--lock-all-tables` (19 s) -> transfer (369 MB) -> drop/recreate/restore (3m40s)
-> row counts verified identical (61 tables, 7,954,543 rows) -> assets re-synced ->
app vhost back -> certbot -> cron installed on new box only.

**DNS is at Cloudflare, not GoDaddy** — the domain is registered at GoDaddy but the
nameservers are `jermaine.ns.cloudflare.com` / `robin.ns.cloudflare.com`. TTLs were
already 300 s so no pre-lowering was needed. Changed: A `intermix.org` and A
`voh.intermix.org` to 5.78.151.159, and the SPF TXT to `ip4:5.78.151.159`.
`www.intermix.org` is a CNAME and followed automatically. `mail.intermix.org` was
deliberately left pointing at the old box.

### One thing that bit during cutover

`PassengerMaxPoolSize` and `PassengerPoolIdleTime` are **server-scope only**. Inside
`<VirtualHost>` Apache logs "cannot occur within <VirtualHost> section" and *ignores*
them — so the pool cap protecting this 3.8 GB box was never in effect, and the warning
was buried in a passing `configtest`. They now live in
`/etc/apache2/conf-available/passenger-tuning.conf`. Apache also stayed down after
certbot's reload and needed an explicit `systemctl start`.

### Original runbook (for reference)

**1. Day before.** Lower TTL on `intermix.org` and `voh.intermix.org` A records at GoDaddy
to 300 s. Confirm the current TTL has expired before proceeding.

**2. Stop writes on the old box.** `sudo systemctl stop apache2` on `198.71.53.140`, and
comment out its crontab. The site is down from here; budget 30–45 minutes.

**3. Final database copy.** Re-dump *with the app stopped*, and this time with
`--lock-all-tables` rather than `--single-transaction` — the rehearsal dump was taken live,
which is fine for InnoDB but leaves the 31 MyISAM tables without a consistent snapshot.
Drop and recreate `intermix` on the new box, restore, and re-run the row-count comparison.

**4. Re-sync changed files.** `rsync` `shared/public/images/data`, `ckeditor_assets` and
`public/system` again to pick up anything written since the rehearsal.

**5. Flip.** At GoDaddy point both A records at `5.78.151.159`. Then, as one step: install
the crontabs on the new box (`config/app_crontab.example` + `config/activitypub_crontab.example`,
**without** `SYS_MODE`) and confirm the old box's crontab is still disabled.

**6. TLS.** Once DNS resolves to the new box:
`sudo certbot --apache -d voh.intermix.org -d intermix.org -d www.intermix.org`.
Then add the HTTP→HTTPS `RewriteRule` to `intermix.conf`, matching the old vhost.

**7. SPF.** `intermix.org` currently publishes `v=spf1 ip4:198.71.53.140 ~all`. Change the
IP. Inbound mail is unaffected — the MX for `intermix.org` already points at `mail.cr8.com`
(94.130.187.48), not at either of these boxes.

**8. Optional:** set rDNS on the Hetzner IP if anything sends mail directly.

**9. Point `config/deploy/production.rb` at the new host** and delete
`config/deploy/newprod.rb`.

**10. Watch.** Error mail, `cron_watchdog` output, and the ActivityPub queues for 24 h.

## After

- Keep the IONOS box running, with Apache and cron **off**, for about a month.
- Check the IONOS notice period before cancelling — dedicated servers often have minimum
  terms, and that may set the timeline.
- The domains are at **GoDaddy** in Roger's name, so cancelling the server cannot take a
  domain with it.
- Not migrated, deliberately: `/home/backup` (19 GB), `/home/oldintermix` (14 GB), the three
  Rails apps last touched in 2011 (`diaspora`, `bettermeans`, `attaway`), the 2016 WordPress
  at `/home/intermix/wpintermix`, and roger's static sites — none of which resolve to the box.
  Archive anything wanted from those **before** cancellation.

## Backups (added 2026-08-15, after the cutover)

The migration did not carry any backup across, and for about ten hours the new box
had none at all. The old box's `dbbackup.php` wrote to `/home/backup` **on the same
machine and the same RAID array**, and used `--single-transaction`, so the 31 MyISAM
tables were never consistent in it. Three layers now:

**1. On-box, nightly.** `script/db_backup.sh` -> `/usr/local/sbin/intermix-db-backup`,
10:00 UTC (03:00 Pacific) from **root's** crontab. Runs as root so mysqldump can
authenticate over the unix socket -- no credentials in the script, the crontab or the
environment, and no need to grant global `RELOAD` to the application's own DB user
just so it can take a backup. `--lock-all-tables` so MyISAM is consistent; binary +
hex-blob so the dump is a faithful copy of the mixed-charset schema. Writes to
`/var/backups`, deliberately outside the deploy tree. Keeps 7 daily + 8 weekly
(~5.5 GB of 64 GB free). Refuses to keep a dump that fails `gzip -t` or is
implausibly small, and writes through `.partial` -- a truncated backup is worse than
none, because it still looks like one.

**2. Offsite, nightly.** `script/offsite_backup.sh` ->
`/usr/local/sbin/intermix-offsite-backup`, 10:30 UTC. rsync over SSH to a Hetzner
Storage Box (`u651366.your-storagebox.de`, **port 23**, key-only via
`/root/.ssh/id_ed25519_storagebox`; settings in root-only
`/etc/intermix-offsite.conf`). Ships the dumps, `public/images/data` (66 MB of user
photos, not in git and not reconstructible) and the three linked config files
(`master.key` above all). Refuses to run if the newest local dump is >2 days old, so a
silently broken `db_backup.sh` cannot leave a healthy-looking offsite copy quietly
going stale. First run: 52 s, 441 MB, verified byte-identical by full checksum compare.

Plain rsync of plain `.sql.gz`, not Borg, on purpose: Borg would dedupe and encrypt
and store this far more efficiently, but needs Borg and a passphrase to read, and a
lost passphrase makes the backup worthless. These restore with the Storage Box
password and `gunzip`, by anyone. The trade-off is that the dump sits unencrypted at
rest on a private key-authenticated box, and it contains participant emails and bcrypt
hashes. Switch to Borg or pipe through `age` if that is not good enough.

**3. Storage Box snapshots.** Set an automatic **daily** plan in the Hetzner console
(10 slots). This is the layer rsync cannot provide: the sync uses `--delete-after` and
therefore faithfully mirrors destruction. Snapshots are taken on Hetzner's side and
**the server's key cannot alter or delete them**, so they survive a compromise of
`intermix-prod` itself. Schedule around 11:00 UTC so each one captures a completed sync.

**All of it is watched.** `db_backup` and `offsite_backup` are in `cron_watchdog.rb`'s
`JOBS`, so they alert if they stop running -- and `/^\S+ FAILED:/` is in
`ERROR_SIGNATURES`, because a backup that runs on schedule and fails every time keeps
refreshing its log mtime and would otherwise look perfectly healthy. Watchdog now
reports `OK 0/9 failing`.

### Restore

    gunzip -c /var/backups/intermix/db/daily/intermix-YYYY-MM-DD.sql.gz \
      | mariadb --default-character-set=binary <database>

Use `--default-character-set=binary`, matching the dump. Tested on 2026-08-15 into a
throwaway database: 61 tables, 1333 participants, 2076 items, matching live.
