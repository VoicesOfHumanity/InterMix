# frozen_string_literal: true

# Rails 7.1 upgrade: incremental migration of the NEW framework defaults that
# `config.load_defaults 7.1` turns on (on top of 7.0). Same approach as the
# 6_0/6_1/7_0 files: pin the behaviorally-risky flips back to legacy behavior,
# migrate each deliberately with a staging re-test, delete this file when empty.
#
# The 6_0/6_1/7_0 pins still apply (their files remain); this covers only the
# 7.0 → 7.1 delta. (cache_format_version stays pinned at 6.1 in the 7_0 file.)

# --- PINNED (risky, migrate later) ---------------------------------------

# NOTE two 7.1 defaults are pinned in config/application.rb instead of here,
# because they are read EARLY (before config/initializers run):
#   * default_column_serializer (7.1 => nil) — the app uses bare `serialize :col`
#     in ~10 models, which raises "missing keyword: :coder" without a default
#     coder. Pinned to YAML in application.rb.
#   * add_autoload_paths_to_load_path (7.1 => false) — LEFT on the 7.1 default;
#     the app has no bare `require` of app-dir files, so dropping app/* from
#     $LOAD_PATH is safe (verified).

# run_commit_callbacks_on_first_saved_instances_in_transaction (7.1 => true):
# changes which instance runs after_commit when the same record is saved more
# than once in a transaction. Keep legacy (last-instance) semantics until the
# AP/item save paths are checked.
Rails.application.config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction = false

# raise_on_assign_to_attr_readonly (7.1 => true): assigning to an attr_readonly
# attribute now raises instead of being silently ignored on update. Keep legacy
# (silent) to avoid surprise 500s on existing update paths.
Rails.application.config.active_record.raise_on_assign_to_attr_readonly = false

# Message serializer (7.1 => :json_allow_marshal) + metadata serializer: these
# change the on-the-wire format of signed/encrypted messages (cookies, tokens).
# Keep legacy Marshal so existing sessions/tokens stay valid, consistent with
# the cookie/message-encryption pins in new_framework_defaults_6_0.rb.
Rails.application.config.active_support.message_serializer = :marshal
Rails.application.config.active_support.use_message_serializer_for_metadata = false
