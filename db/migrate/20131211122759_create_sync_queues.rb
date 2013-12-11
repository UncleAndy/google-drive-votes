class CreateSyncQueues < ActiveRecord::Migration
  def change
    create_table :sync_queues do |t|
      t.string :status, :null => false, :limit => 8
      t.string :query_id, :null => false, :limit => 32
      t.string :cmd, :null => false, :limit => 16
      t.text :data, :null => false
      
      t.timestamps
    end

    add_index :sync_queues, :query_id
    add_index :sync_queues, [ :status, :created_at ]
  end
end
