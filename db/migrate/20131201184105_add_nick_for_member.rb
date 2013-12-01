class AddNickForMember < ActiveRecord::Migration
  def up
    add_column :trust_net_members, :nick, :string, :limit => 128
  end

  def down
    remove_column :trust_net_members, :nick
  end
end
