class CreateSyncHosts < ActiveRecord::Migration
  def change
    create_table :sync_hosts do |t|
      t.string :url, :null => true, :limit => 255
      t.string :secret, :null => false, :limit => 255
      t.string :host_id, :null => false, :limit => 32
      t.boolean :active, :null => false, :default => true
      
      t.timestamps
    end

    add_index :sync_hosts, :host_id
  end
end
