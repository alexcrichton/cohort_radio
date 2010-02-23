class MakePriorityFloat < ActiveRecord::Migration
  def self.up
    change_column :queue_items, :priority, :float
  end

  def self.down
    change_column :queue_items, :priority, :integer
  end
end
