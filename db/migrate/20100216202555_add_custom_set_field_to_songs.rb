class AddCustomSetFieldToSongs < ActiveRecord::Migration
  def self.up
    add_column :songs, :custom_set, :boolean
  end

  def self.down
    remove_column :songs, :custom_set
  end
end
