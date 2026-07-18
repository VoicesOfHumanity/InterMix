# frozen_string_literal: true

# Rails 8.0 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 8.0` turns on (on top of 7.2). Same approach as the
# earlier files: pin the behaviorally-risky flips back to legacy behavior,
# migrate each deliberately with a staging re-test, delete when empty.
#
# The earlier pin files still apply; this covers only the 7.2 → 8.0 delta.

# --- MIGRATED --------------------------------------------------------------
#
# raise_on_missing_callback_actions: a controller raises at request time if a
# before/after_action's :only/:except names an action the controller doesn't
# define. This flag is NOT part of load_defaults (its mattr default is false),
# so it must be enabled explicitly. Audited every controller (replicating
# Rails' ActionFilter#match? check via available_action?): the only stale
# references were three :except lists on ConversationsController naming a
# long-gone :join action — removed those. Now enabled, so a future stale filter
# surfaces loudly instead of silently mis-scoping a callback.
Rails.application.config.action_controller.raise_on_missing_callback_actions = true

# strict_freshness (8.0 => true): ETag takes precedence over Last-Modified per
# RFC 7232 when both conditional headers are present. Verified no-op here — the
# app uses no conditional GET (no fresh_when/stale?/etag/last_modified anywhere),
# so there are never both headers to arbitrate. Removed the pin; load_defaults
# 8.0 now sets it true (verified applied).
