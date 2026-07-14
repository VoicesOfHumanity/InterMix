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
# HIGH RISK. 76 of 93 belongs_to associations have no optional:/required:.
# Enabling this makes every one required, so any save with a nil FK
# (poster_id, complainer_id, geo lookups, creator, ...) fails validation.
# Migrate only after auditing each association and marking the genuinely
# optional ones `optional: true`.
Rails.application.config.active_record.belongs_to_required_by_default = false

# Per-form CSRF tokens and Origin-header forgery check. Legacy off.
Rails.application.config.action_controller.per_form_csrf_tokens = false
Rails.application.config.action_controller.forgery_protection_origin_check = false

# --- 5.1 -----------------------------------------------------------------
# form_with would generate remote (AJAX) forms by default. Keep local.
Rails.application.config.action_view.form_with_generates_remote_forms = true

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
# Keep the hidden utf8 form field (default_enforce_utf8 true) so form markup
# is identical to before.
Rails.application.config.action_view.default_enforce_utf8 = true

# Purpose+expiry metadata embedded in signed/encrypted cookies changes the
# cookie format; keep legacy to avoid churn alongside the encryption pins.
Rails.application.config.action_dispatch.use_cookies_with_metadata = false

# Collection cache versioning — deferred with the rest of the caching work.
Rails.application.config.active_record.collection_cache_versioning = false
