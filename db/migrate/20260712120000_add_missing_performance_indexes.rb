class AddMissingPerformanceIndexes < ActiveRecord::Migration[5.2]
  # Indexes flagged by the 2026-07 audit as missing on hot lookup paths.
  # Guarded so the migration is safe to run against a DB where an index may
  # already have been added by hand.
  def change
    add_index :items, :reply_to, name: "index_items_on_reply_to" unless index_exists?(:items, :reply_to, name: "index_items_on_reply_to")

    unless index_exists?(:ratings, [:dialog_id, :period_id], name: "index_ratings_on_dialog_id_and_period_id")
      add_index :ratings, [:dialog_id, :period_id], name: "index_ratings_on_dialog_id_and_period_id"
    end

    unless index_exists?(:participants, :authentication_token, name: "index_participants_on_authentication_token")
      add_index :participants, :authentication_token, name: "index_participants_on_authentication_token"
    end

    unless index_exists?(:authentications, [:provider, :uid], name: "index_authentications_on_provider_and_uid")
      # authentications is MyISAM/utf8; two full varchar(255) columns blow past
      # the 1000-byte key limit, so index prefixes (plenty for provider names and
      # OAuth uids).
      add_index :authentications, [:provider, :uid], name: "index_authentications_on_provider_and_uid", length: { provider: 64, uid: 128 }
    end

    add_index :api_requests, :processed, name: "index_api_requests_on_processed" unless index_exists?(:api_requests, :processed, name: "index_api_requests_on_processed")
    add_index :api_requests, :redo, name: "index_api_requests_on_redo" unless index_exists?(:api_requests, :redo, name: "index_api_requests_on_redo")
  end
end
