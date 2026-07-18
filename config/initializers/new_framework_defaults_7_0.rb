# frozen_string_literal: true

# Rails 7.0 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 7.0` turns on (on top of 6.1). Same approach as the
# 6_0/6_1 files: pin the behaviorally-risky flips back to legacy behavior,
# migrate each deliberately with a staging re-test, delete this file when empty.
#
# The 6_0 and 6_1 pins still apply (their files remain); this covers only the
# 6.1 → 7.0 delta.

# --- PINNED (risky, migrate later) ---------------------------------------

# raise_on_open_redirects (7.0 => true): redirect_to an external host now RAISES
# unless allow_other_host: true. The app does external redirects (OAuth provider
# callbacks, cross-domain voh/intermix hops). Keep legacy (no raise) until every
# external redirect_to is audited + marked allow_other_host.
Rails.application.config.action_controller.raise_on_open_redirects = false

# button_to_generates_button_tag (7.0 => true): button_to renders <button>
# instead of <input type=submit>, which changes markup/CSS/JS hooks. Keep the
# <input> form until the UI is checked.
Rails.application.config.action_view.button_to_generates_button_tag = false

# partial_inserts: MIGRATED to the 7.0 default (false) — INSERTs now always
# include every column (with its default), which is the safer, explicit form on
# MyISAM. Verified: boot + suite green, record creation exercised.

# automatic_scope_inversing: MIGRATED to the 7.0 default (true). Boot + full
# suite green (association loading through the metamap/dialog/community models
# exercised by the model specs).

# cache_format_version: MIGRATED — removed the 6.1 pin; load_defaults 8.0 sets
# the current format. Cold-cache-only (default file store, app barely caches).
