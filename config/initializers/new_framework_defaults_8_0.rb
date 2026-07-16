# frozen_string_literal: true

# Rails 8.0 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 8.0` turns on (on top of 7.2). Same approach as the
# earlier files: pin the behaviorally-risky flips back to legacy behavior,
# migrate each deliberately with a staging re-test, delete when empty.
#
# The earlier pin files still apply; this covers only the 7.2 → 8.0 delta.

# --- PINNED (risky, migrate later) ---------------------------------------

# raise_on_missing_callback_actions (8.0 => true): a controller raises at
# request time if a before/after_action's :only/:except names an action the
# controller doesn't define. Old controllers here have accumulated such
# filters; keep legacy (silently ignore) until they're audited, so no page
# 500s on a stale filter reference.
Rails.application.config.action_controller.raise_on_missing_callback_actions = false

# strict_freshness (8.0 => true): makes ETag take precedence over
# Last-Modified per RFC 7232 when both conditional headers are present, which
# changes 304 behavior. Keep legacy precedence until HTTP caching is reviewed.
Rails.application.config.action_dispatch.strict_freshness = false
