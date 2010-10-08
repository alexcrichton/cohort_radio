class RemoveComments < ActiveRecord::Migration
  def self.up
    drop_table :comments
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
