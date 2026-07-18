# frozen_string_literal: true

# Rails 7.0 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 7.0` turns on (on top of 6.1). Same approach as the
# 6_0/6_1 files: pin the behaviorally-risky flips back to legacy behavior,
# migrate each deliberately with a staging re-test, delete this file when empty.
#
# The 6_0 and 6_1 pins still apply (their files remain); this covers only the
# 6.1 → 7.0 delta.

# --- PINNED (risky, migrate later) ---------------------------------------

# raise_on_open_redirects: MIGRATED to the 7.0 default (true). Audited every
# redirect_to: the internal `/path` redirects are same-origin (no raise); the 18
# cross-host ones (protocol-relative `//BASEDOMAIN/...` join/slider hops and
# `//shortname.ROOTDOMAIN/` subdomain hops in front/communities/groups
# controllers, all to the app's OWN domains) are now marked allow_other_host:
# true. Removed the pin. NB: user-supplied redirect targets would now raise —
# none found (no redirect_to params[...]/return_to/referer in the app).

# button_to_generates_button_tag: MIGRATED to the 7.0 default (true). Audited
# all 7 button_to sites: 6 are block-form OAuth login buttons (`button_to url do`)
# which ALWAYS render <button> regardless of this flag; only the
# delete-account button (front/delete_account_screen) is non-block and switches
# <input> -> <button> (same .btn styling, text label preserved). Needs a quick
# visual confirm on staging. Removed the pin.

# partial_inserts: MIGRATED to the 7.0 default (false) — INSERTs now always
# include every column (with its default), which is the safer, explicit form on
# MyISAM. Verified: boot + suite green, record creation exercised.

# automatic_scope_inversing: MIGRATED to the 7.0 default (true). Boot + full
# suite green (association loading through the metamap/dialog/community models
# exercised by the model specs).

# cache_format_version: MIGRATED — removed the 6.1 pin; load_defaults 8.0 sets
# the current format. Cold-cache-only (default file store, app barely caches).
