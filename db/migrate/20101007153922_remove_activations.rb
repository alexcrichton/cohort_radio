class RemoveActivations < ActiveRecord::Migration
  def self.up
    drop_table :activations
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
