class CreateUserPropertyVotes < ActiveRecord::Migration
  def change
    create_table :user_property_votes do |t|
      t.string :idhash, :limit => 64, :null => false
      t.string :doc_key, :limit => 64, :null => false
      t.string :vote_idhash, :limit => 64, :null => false
      t.string :vote_property_key, :limit => 255, :null => true
      t.integer :vote_property_level, :in => -10..10, :null => false

      t.timestamps
    end

    add_index :user_property_votes, [:idhash, :doc_key]
    add_index :user_property_votes, [:vote_property_key, :vote_idhash, :vote_property_level], :name => 'user_property_pkey_hash_level'
    add_index :user_property_votes, [:vote_idhash, :vote_property_key, :vote_property_level], :name => 'user_pkey_property_hash_level'
  end
end
