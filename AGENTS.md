# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## On Session Start

1. Read all core project files in this order:
   - `PROJECT.md` — purpose, scope, key decisions, and technical conventions
   - `STATUS.md` — current state, what's in progress, what's next
   - `REGISTRY.md` — index of key artifacts
   - `CONVENTIONS.md` — how to behave, naming rules, quality standards
   - the rest of *this* file — stack, architecture, commands, and gotchas
2. If `ORCHESTRATION.md` exists, read it too — it wires this project into the local multi-project ecosystem (scheduled runs, outbox reports, the central Orchestration project). If it doesn't exist, this is a standalone project; skip everything orchestration-related.
3. If `git` is available and the project folder is not a git repository, run `git init` and make an initial commit. If a commit fails because git has no identity configured, set a repo-local `user.name` and `user.email` (ask the user what to use) — do not touch their global config. If `git` is not installed, silently skip every git-related instruction.
4. Briefly confirm your understanding of the current state.
5. Propose what to work on based on the "Up Next" section of STATUS.md, unless the user directs otherwise.

## During the Session

- Update `STATUS.md` immediately after completing any significant piece of work — do not wait for session end. Sessions can end abruptly, and STATUS.md must always be safe to resume from cold.
- Commit after each significant, working change with a brief descriptive message. Do not ask permission to commit; just do it. Never push without asking.
- Add meaningful new artifacts to `REGISTRY.md` as they're created.

## On Session End

1. Update `STATUS.md` — move completed items, update "In Progress" and "Up Next".
2. Update `REGISTRY.md` — add new artifacts, note deprecations.
3. Append a session entry to `LOG.md` with the date, what was done, and what to do next.
4. Update `PROJECT.md` only if a key decision was made or scope changed.
5. Show the user the changes, then commit.

## Important Notes

- `README.md` is for the user, not for you. Do not modify it unless asked.
- Do not create files outside the project folder structure.
- Do not delete or overwrite files without asking. Move old versions to `deprecated/` or note them in REGISTRY.md.
- Do not make assumptions about scope changes. If something seems out of scope, ask.

## Project Overview

InterMix is a civic engagement and dialogue platform ("Building a global consciousness from the bottom up"). It enables structured conversations, communities, groups, and dialogs with voting/rating systems. It supports ActivityPub federation.

## Tech Stack

- **Ruby:** 2.7.7 (rbenv)
- **Rails:** 5.2.3
- **Database:** MySQL (mysql2 gem, mix of MyISAM and InnoDB tables, UTF8mb4)
- **Auth:** Devise + OmniAuth (Facebook, Google, Twitter)
- **Authorization:** CanCanCan
- **File uploads:** Paperclip
- **Rich text:** CKEditor (vendored in public/javascripts/ckeditor/)
- **Views:** ERB templates
- **Asset pipeline:** Sprockets (no Webpacker despite node_modules presence)

## Common Commands

```bash
bundle install                    # install dependencies
rails server                     # start dev server
rails console                    # interactive console
rake db:migrate                  # run migrations
rake assets:precompile            # compile assets
rspec                            # run all tests
rspec spec/path/to_spec.rb       # run single test file
rspec spec/path/to_spec.rb:42    # run single test at line
```

## Deployment

Capistrano 3 deploys to single-server environments via SSH (user: `ploy`).

```bash
bundle exec cap staging deploy     # deploy to staging
bundle exec cap production deploy  # deploy to production
```

- **Deploy target:** `/home/apps/intermix`
- **Shared/linked files:** `config/database.yml`, `config/localsettings.rb`, `config/master.key`
- **Shared dirs:** `bin`, `log`, `tmp`, `vendor/bundle`, `public/system`, `public/images/data`, `public/ckeditor_assets`
- **Server configs:** `config/deploy/staging.rb`, `config/deploy/production.rb`
- Restart mechanism: `touch tmp/restart.txt` (Passenger)
- Post-deploy: asset precompile, migrations, sitemap generation

## Architecture

### Core Domain Models

- **Participant** — users (Devise authentication). Not called "User".
- **Community** — topic-based groups (UN goals, demographics, cities, religions, etc.). Categorized by `which` parameter in routes.
- **Conversation** — discussion threads tied to communities
- **Dialog** — structured dialogues with metamaps (voting/categorization), time periods ("moons"), and group settings
- **Group** — user-created discussion spaces with subgroups, moderation, and dialog integration
- **Item** — posts/messages across forum, wall, profile, and conversations. Central content unit.
- **Rating/Vote** — thumbs and importance ratings on items
- **Network** — connections/relationships between participants
- **Metamap** — visual/structured categorization with nodes, used in dialogs

### Key Relationships

Communities, conversations, groups, and dialogs all interconnect. Groups can contain dialogs; dialogs use metamaps; communities contain conversations. Participants join communities, groups, and dialogs through join tables.

### Controllers

- **Front-facing:** `FrontController` (landing, registration flows, helpers), `ForumController`, `PeopleController`, `WallController`
- **Resource controllers:** Communities, Conversations, Groups, Dialogs, Items, Messages, Networks, Profiles
- **Admin namespace:** Full CRUD admin panel under `Admin::` namespace at `/admin/`
- **API:** `ApiController` — REST API for mobile apps (login, register, posts, ratings, complaints)
- **ActivityPub:** `ActivitypubController` + `WellKnownController` — federation protocol support

### Global Constants

`config/application.rb` defines important constants: `DEFAULT_COMMUNITIES` (40+ predefined community tags), participant statuses, visibility levels, email preferences, gender/age crosstalk options, and the "Moons" lunar calendar system.

### Environment Detection

Production environment uses hostname/`SYS_MODE` env var to distinguish staging vs production (cr8.com vs intermix.org). See `config/environments/production.rb`.

### Sensitive Config

Database passwords, API keys (Facebook, Twitter, Postmark) are in Rails encrypted credentials (`config/master.key` required). Local overrides in `config/localsettings.rb`. Never commit these files.

