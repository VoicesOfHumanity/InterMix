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

# automatically_invert_plural_associations: MIGRATED to the 7.2 recommended
# value (true). NB this is NOT set by load_defaults (its mattr default is false),
# so it must be enabled explicitly. Boot + full suite green.
Rails.application.config.active_record.automatically_invert_plural_associations = true

# yjit: MIGRATED — removed the pin; load_defaults 8.0 sets it true. Verified a
# genuine no-op on both local and the production server: their Ruby 3.2.11 is
# built WITHOUT YJIT (RubyVM::YJIT absent), so Rails' enable step is skipped.
# Becomes a real perf win only after Ruby is rebuilt with YJIT (ties to the
# deferred Passenger/OS modernization).
