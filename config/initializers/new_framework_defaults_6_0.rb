# frozen_string_literal: true

# Rails 6.0 upgrade (step 3): incremental migration of new framework defaults.
#
# `config.load_defaults 6.0` (in application.rb) turns on every framework
# default from 5.0 through 6.0 at once. Because this app previously had NO
# load_defaults line, it was running on pre-5.0 behavior, so that switch flips
# a large stack of defaults simultaneously. To keep this step behavior-neutral,
# the behaviorally-risky flips are PINNED BACK to their legacy values below.
#
# Migrate them ONE AT A TIME in later increments: delete (or flip) a line here,
# run the suite, click through staging, commit. When this file is empty, the
# app is fully on 6.0 defaults and the file can be removed.
#
# The safe/inert new defaults (e.g. to_time_preserves_timezone, ActiveStorage
# queue names — app uses Paperclip, not ActiveStorage) are intentionally left
# ENABLED and not listed here.

# --- 5.0 -----------------------------------------------------------------
# belongs_to_required_by_default: MIGRATED (now on the 6.0 default = true).
# Audited all 93 belongs_to against DB nullability + real null counts: every
# FK column is nullable except Block.blocker_id/blocked_id (NOT NULL), and
# many carry real nulls (Item.conversation_id 750/918, Participant geo FKs,
# Rating.period_id 294/538, ...). Marked the 68 nullable associations
# `optional: true`; left Block required (DB-enforced). Byte-neutral flip.

# per_form_csrf_tokens / forgery_protection_origin_check: MIGRATED (on the
# 6.0 defaults = true). Low blast radius; suite + boot verified.

# --- 5.1 -----------------------------------------------------------------
# form_with_generates_remote_forms: pin removed. NOTE this stays true under
# 6.0 (the flip to local-by-default false is a 6.1 default, so it belongs to
# the 6.1 step, not here). Only 4 form_with call sites in the app.

# --- 5.2 -----------------------------------------------------------------
# Authenticated cookie/message encryption: flipping these invalidates every
# existing session cookie (logs all users out). Keep legacy until a chosen
# maintenance window.
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false
Rails.application.config.active_support.use_authenticated_message_encryption = false

# Cache-key digest and versioning. Caching work is deferred (see STATUS.md);
# keep legacy digest + non-versioned keys so cache behavior is unchanged.
Rails.application.config.active_support.hash_digest_class = OpenSSL::Digest::MD5
Rails.application.config.active_record.cache_versioning = false

# --- 6.0 -----------------------------------------------------------------
# default_enforce_utf8: MIGRATED (on the 6.0 default = false). Drops the
# hidden `utf8=✓` snowman field from forms; only mattered for pre-modern IE.

# Purpose+expiry metadata embedded in signed/encrypted cookies changes the
# cookie format; keep legacy to avoid churn alongside the encryption pins.
Rails.application.config.action_dispatch.use_cookies_with_metadata = false

# Collection cache versioning — deferred with the rest of the caching work.
Rails.application.config.active_record.collection_cache_versioning = false
