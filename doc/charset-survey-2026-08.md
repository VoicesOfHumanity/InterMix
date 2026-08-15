# Charset survey — 2026-08-15

Read-only survey of production (`5.78.151.159`, MariaDB 10.11), run to answer one
question before anyone attempts a charset migration: **would converting this schema to
utf8mb4 mangle the data?**

Short answer: **no.** The feared double-encoding is not there. The real obstacle is
index length on the MyISAM tables, not the content.

## Why this came up

`communities#fronttag` was 500ing with `Mysql2::Error: Illegal mix of collations
(latin1_swedish_ci,IMPLICIT) and (utf8mb4_unicode_ci,COERCIBLE)`. Comparing a latin1
column against a string latin1 cannot represent raises rather than simply not matching.
Boundary guards are deployed (`latin1_storable?`), but they are a workaround; converting
the columns is the cure.

Note this is **not only a latin1 problem**. A utf8mb3 column compared against an astral
character (emoji, U+10000 and above) raises the same way — utf8mb3 cannot store 4-byte
characters. latin1 breaks on any non-ASCII; utf8mb3 breaks only on emoji.

## The schema

| charset | columns | tables | notes |
|---|---|---|---|
| utf8mb3 | 257 | 38 | includes `geonames` (7.4M rows, most of the 2.4 GB) |
| latin1 | 68 | 10 | biggest is `emails` (289k rows) |
| utf8mb4 | 26 | 1 | `items` — the main content table, already correct |

Engines: **30 InnoDB, 31 MyISAM.** All InnoDB tables are `Dynamic` row format.

## Finding 1 — the data is clean

Method: `SELECT HEX(col)` so the driver never re-encodes anything, then classify the raw
bytes in Ruby.

**latin1 columns: 7 of 68 contain any non-ASCII at all, totalling ~22 rows in the entire
database.** Every one is genuine single-byte latin1. **Zero double-encoded values.**

    communities.description      4      communities.logo_file_name   4
    communities.front_template   5      help_texts.text              3
    periods.shortdesc            2      periods.instructions         3
    periods.result               1

`emails` (289k rows, 2 latin1 columns) contains **no** non-ASCII whatsoever.

Content is things like `Réunion`, `Côte d'Ivoire`, `1986–2010`. Worth knowing:
**MySQL/MariaDB "latin1" is really cp1252**, not strict ISO-8859-1, so bytes in 0x80–0x9F
are real characters (curly quotes, en-dashes) and `CONVERT TO CHARACTER SET` maps them
correctly. Those show as `?` in the raw survey output only because the classifier decoded
with ISO-8859-1 — a display artefact, not damage.

**utf8mb3 columns:** all valid UTF-8, no mojibake, no invalid sequences. Conversion to
utf8mb4 is a pure widening. **utf8mb4 (`items`):** clean.

## Finding 2 — the indexes are the actual blocker

utf8mb4 is 4 bytes/char, so every index prefix on a character column grows.
**MyISAM's key limit is 1000 bytes; InnoDB Dynamic gives 3072.**

13 indexes would exceed the limit, all `varchar(255)` on MyISAM tables, all 765 B → 1020 B:

    participants   email, authentication_token, confirmation_token, reset_password_token
    taggings       context, taggable_type, tagger_type
    tags           name
    groups         name
    hubs           name
    geocountries   name, sortname
    schema_migrations  version

The `participants` ones are on the sign-in path, so this cannot be fudged.

**No InnoDB index has a problem** — the 3072-byte limit absorbs 1020 comfortably.

## Recommended sequence

**Phase 0 — done.** `latin1_storable?` guards on `communities#fronttag`,
`conversations#fronttag`, `profiles#comtag`. The 500s have stopped.

**Phase 1 — MyISAM → InnoDB.** This removes the index blocker entirely by raising the key
limit from 1000 to 3072 bytes, and is worth doing on its own merits: MyISAM has no
transactions and no crash recovery. It would also let `db_backup.sh` drop
`--lock-all-tables` for `--single-transaction`, i.e. backups with no write lock at all.

**Phase 2 — latin1 → utf8mb4** on the 68 columns. Only ~22 rows carry non-ASCII, all
convertible, so a straight `CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
is safe. This is what actually fixes `fronttag`.

**Phase 3 — optional: utf8mb3 → utf8mb4.** Pure widening, but `geonames` is 7.4M rows and
will take a while. Only needed to make emoji in a URL as safe as accented characters.
`geonames` is reference data and could be left until last, or left alone.

Rehearse the whole thing first by restoring the nightly backup into a scratch database on
the same box — that costs ~4 minutes and ~2.4 GB, and exercises the backup as a bonus.

## Caveats

- `geonames`, `sessions`, `emails` and `geoadmin2s` were sampled at 50k rows rather than
  fully scanned. The smaller tables — including every latin1 one that matters — were
  scanned completely.
- The mojibake test is a heuristic (it looks for the classic Ã/Â/â€ signatures). Zero hits
  across every column of every charset is a strong signal, not a proof.
- Row counts come from `information_schema` and are approximate; the byte scans are exact.
