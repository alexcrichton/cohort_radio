class RemoveUnnecessaryFields < ActiveRecord::Migration
  def self.up
    remove_column :songs, :album
    remove_column :songs, :artist
    remove_column :songs, :album_image_url
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
