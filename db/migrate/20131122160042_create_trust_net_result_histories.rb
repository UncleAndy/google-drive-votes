class CreateTrustNetResultHistories < ActiveRecord::Migration
  def up
    create_table :trust_net_result_histories do |t|
      t.timestamp :result_time, :null => false
    end
    add_index :trust_net_result_histories, :result_time

    add_column :trust_net_results, :result_time, :timestamp, :null => false
    add_index :trust_net_results, [:result_time, :verify_level]
    add_index :trust_net_results, [:result_time, :idhash, :doc_key]
  end

  def down
    remove_index :trust_net_results, [:result_time, :idhash, :doc_key]
    remove_index :trust_net_results, [:result_time, :verify_level]
    remove_column :trust_net_results, :result_time
    
    drop_table :trust_net_result_histories
  end
end
