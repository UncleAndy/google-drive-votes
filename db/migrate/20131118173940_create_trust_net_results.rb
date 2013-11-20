class CreateTrustNetResults < ActiveRecord::Migration
  def change
    create_table :trust_net_results do |t|
      t.string :idhash, :limit => 64, :null => false
      t.string :doc_key, :limit => 64, :null => false
      t.float :verify_level, :precision => 4, :scale => 2, :null => false
      t.float :trust_level, :precision => 4, :scale => 2, :null => false
      t.integer :votes_count, :null => false

      t.timestamps
    end

    add_index :trust_net_results, [ :idhash, :doc_key ]
    add_index :trust_net_results, [ :verify_level, :votes_count ]
  end
end
