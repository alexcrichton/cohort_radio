class RemoveUnusedColumns < ActiveRecord::Migration
  def self.up
    remove_column :songs, :audio_content_type
    remove_column :songs, :audio_file_size
    remove_column :songs, :audio_updated_at
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
