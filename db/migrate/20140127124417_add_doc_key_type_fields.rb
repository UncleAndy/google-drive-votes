class AddDocKeyTypeFields < ActiveRecord::Migration
  def up
    add_column :trust_net_members, :doc_key_type, :string, :limit => 32, :default => 'GOOGLEDOC'
    add_column :trust_net_results, :doc_key_type, :string, :limit => 32, :default => 'GOOGLEDOC'
    add_column :user_property_votes, :doc_key_type, :string, :limit => 32, :default => 'GOOGLEDOC'
    add_column :user_trust_votes, :doc_key_type, :string, :limit => 32, :default => 'GOOGLEDOC'
    add_column :user_verify_votes, :doc_key_type, :string, :limit => 32, :default => 'GOOGLEDOC'
    add_column :user_verify_votes, :vote_doc_key_type, :string, :limit => 32, :default => 'GOOGLEDOC'
  end

  def down
    remove_column :trust_net_members, :doc_key_type
    remove_column :trust_net_results, :doc_key_type
    remove_column :user_property_votes, :doc_key_type
    remove_column :user_trust_votes, :doc_key_type
    remove_column :user_verify_votes, :doc_key_type
    remove_column :user_verify_votes, :vote_doc_key_type
  end
end
