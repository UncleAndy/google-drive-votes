class AddDocKeyForTrustNetVotes < ActiveRecord::Migration
  def up
    execute <<-SQL
      delete from user_trust_net_votes;
    SQL
    add_column :user_trust_net_votes, :doc_key, :string, :limit => 64, :null => false
  end

  def down
    drop_column :user_trust_net_votes, :doc_key
  end
end
