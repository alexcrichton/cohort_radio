class AddDeviseForUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.database_authenticatable
      t.confirmable
      t.recoverable
      t.rememberable
      t.trackable
    end

    rename_column :users, :crypted_password, :encrypted_password
    remove_column :users, :perishable_token
    remove_column :users, :persistence_token
    remove_column :users, :single_access_token

    User.update_all :confirmed_at => Time.now
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
