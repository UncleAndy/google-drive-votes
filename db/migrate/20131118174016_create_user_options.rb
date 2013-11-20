class CreateUserOptions < ActiveRecord::Migration
  def change
    create_table :user_options do |t|
      t.string :idhash, :limit => 64, :null => false
      t.string :emails
      t.string :skype
      t.string :icq
      t.string :jabber
      t.string :phones
      t.string :facebook
      t.string :vk
      t.string :odnoklassniki
      
      t.timestamps
    end

    add_index :user_options, :idhash
  end
end
