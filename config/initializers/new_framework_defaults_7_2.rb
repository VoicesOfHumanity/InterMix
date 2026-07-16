# frozen_string_literal: true

# Rails 7.2 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 7.2` turns on (on top of 7.1). Same approach as the
# 6_0/6_1/7_0/7_1 files: pin the behaviorally-risky flips back to legacy
# behavior, migrate each deliberately with a staging re-test, delete when empty.
#
# The earlier pin files still apply; this covers only the 7.1 → 7.2 delta.

# --- PINNED (risky, migrate later) ---------------------------------------

# (to_time_preserves_timezone is NOT changed by 7.2 — it stays `true`/:offset;
# the :zone default arrives in Rails 8, so nothing to pin here for it.)

# automatically_invert_plural_associations (7.2 => true): AR infers inverse_of
# for has_many/belongs_to whose names differ only by pluralization, which can
# change which records load through associations. Keep legacy (explicit-only)
# until the metamap/dialog/community associations are checked.
Rails.application.config.active_record.automatically_invert_plural_associations = false

# yjit (7.2 => true): auto-enables YJIT. Keep off to match 7.1 (this server's
# Ruby 3.2.11 was built without YJIT anyway, so it is a no-op there). Enable
# later as a deliberate perf step after checking memory on the prod box.
Rails.application.config.yjit = false
