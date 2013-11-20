class CreateUserTrustNetVotes < ActiveRecord::Migration
  def change
    create_table :user_trust_net_votes do |t|
      t.string :idhash, :limit => 64, :null => false
      t.string :vote_idhash, :limit => 64, :null => false
      t.string :vote_doc_key, :limit => 64, :null => false
      t.integer :vote_verify_level, :null => false, :in => -10..10
      t.integer :vote_trust_level, :null => false, :in => -10..10

      t.timestamps
    end

    add_index :user_trust_net_votes, [ :idhash ]
    add_index :user_trust_net_votes, [ :vote_idhash, :vote_doc_key ]
  end
end
