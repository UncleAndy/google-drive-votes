class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.string :url
      
      t.timestamps
    end

    add_index :servers, :url
  end
end
