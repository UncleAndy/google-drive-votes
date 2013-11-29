class SetDocKeyPrimaryKeyForUserOption < ActiveRecord::Migration
  def up
    UserOption.delete_all
    add_column :user_options, :doc_key, :string, :limit => 64, :null => false
  end

  def down
    drop_column :user_options, :doc_key
  end
end
