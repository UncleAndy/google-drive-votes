class CreateTrustNetMembers < ActiveRecord::Migration
  def change
    create_table :trust_net_members do |t|
      t.string :idhash, :limit => 64, :null => false
      t.string :doc_key, :limit => 64, :null => false

      t.timestamps
    end

    add_index :trust_net_members, [ :idhash, :doc_key ]
  end
end
