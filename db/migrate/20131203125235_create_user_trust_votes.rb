class CreateUserTrustVotes < ActiveRecord::Migration
  def change
    create_table :user_trust_votes do |t|
      t.string :idhash, :limit => 64, :null => false
      t.string :doc_key, :limit => 64, :null => false
      t.string :vote_idhash, :limit => 64, :null => false
      t.integer :vote_trust_level, :in => -10..10, :null => false
      
      t.timestamps
    end
    add_index :user_trust_votes, [:idhash, :doc_key]
    add_index :user_trust_votes, [:vote_idhash]
  end
end
