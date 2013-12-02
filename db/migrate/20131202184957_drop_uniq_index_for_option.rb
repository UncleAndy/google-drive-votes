class DropUniqIndexForOption < ActiveRecord::Migration
  def up
    remove_index :user_options, :idhash
    add_index :user_options, [:idhash, :doc_key], :unique => true
    
    remove_index :user_trust_net_votes, :name => 'index_utnv_id_vid_vdoc_key'
    add_index :user_trust_net_votes, [ :idhash, :doc_key, :vote_idhash, :vote_doc_key ], :unique => true, :name => 'index_utnv_id_vid_vdoc_key'
  end

  def down
    remove_index :user_options, [:idhash, :doc_key]
    add_index :user_options, :idhash, :unique => true

    remove_index :user_trust_net_votes, :name => 'index_utnv_id_vid_vdoc_key'
    add_index :user_trust_net_votes, [ :idhash, :vote_idhash, :vote_doc_key ], :unique => true, :name => 'index_utnv_id_vid_vdoc_key'
  end
end
