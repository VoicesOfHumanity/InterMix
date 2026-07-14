class AddTriesToApiRequests < ActiveRecord::Migration[5.2]
  def change
    # Number of times activitypub_responses has attempted to process this request.
    # Used to cap retries so a permanently-failing request can't be retried forever
    # (which, combined with processed never being set, caused an ever-growing backlog).
    add_column :api_requests, :tries, :integer, default: 0 unless column_exists?(:api_requests, :tries)
  end
end
