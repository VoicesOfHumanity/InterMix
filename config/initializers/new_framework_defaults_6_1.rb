# frozen_string_literal: true

# Rails 6.1 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 6.1` turns on (on top of 6.0). Same approach as
# new_framework_defaults_6_0.rb: pin the behaviorally-risky flip back to legacy
# behavior, migrate it deliberately with a staging re-test, delete this file
# when empty.
#
# NOTE the 6.0-level pins still live in new_framework_defaults_6_0.rb
# (authenticated cookie/message encryption + the cache-related defaults) and
# remain in force — this file only covers the 6.0→6.1 delta.

# --- ENABLED (left on the 6.1 defaults) ----------------------------------
# cookies_same_site_protection = :lax (6.1 default): adds SameSite=Lax to
# cookies. This is the OAuth-sensitive one — the session cookie must survive
# the cross-site redirect back from Google/Facebook/Twitter. Lax sends cookies
# on top-level redirect-GET navigations (which is how these OAuth callbacks
# return), so it should hold. MIGRATED here; re-verified with a staging OAuth
# test (Google/FB/Twitter) as part of enabling it.
#
# has_many_inversing = true: sets up inverse associations in memory so a parent
# and its loaded children share one object identity. Safe here; no code relies
# on parent/child being distinct instances.
#
# urlsafe_csrf_tokens = true: URL-safe base64 CSRF tokens. Only effect is a
# one-request-window token-format mismatch across the deploy itself (a form
# rendered by the old release fails one submit, then works). Negligible.
#
# active_storage.track_variants = true: inert — this app uses Paperclip, not
# ActiveStorage.
#
# form_with_generates_remote_forms = false (local forms by default): NOT pinned.
# All four form_with call sites now pass an explicit `local: true`, so they are
# independent of this default and the flip is a no-op.
