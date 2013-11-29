class AddDocKeyForTrustNetVotes < ActiveRecord::Migration
  def up
    UserTrustNetVote.delete_all
    add_column :user_trust_net_votes, :doc_key, :string, :limit => 64, :null => false
  end

  def down
    drop_column :user_trust_net_votes, :doc_key
  end
end
