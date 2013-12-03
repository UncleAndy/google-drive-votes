class ChangeModelUserTrustNetVote < ActiveRecord::Migration
  def up
    rename_table :user_trust_net_votes, :user_verify_votes

    remove_column :user_verify_votes, :vote_trust_level
  end

  def down
    add_column :user_verify_votes, :vote_trust_level, :integer, :null => false, :in => -10..10
    
    rename_table :user_verify_votes, :user_trust_net_votes
  end
end
