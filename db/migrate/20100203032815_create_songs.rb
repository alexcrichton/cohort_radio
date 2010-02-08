class CreateSongs < ActiveRecord::Migration
  def self.up
    create_table :songs do |t|
      t.string :artist
      t.string :album
      t.string :title
      t.string :album_image_url
      t.integer :play_count, :default => 0
      
      t.string :audio_file_name
      t.string :audio_content_type
      t.integer :audio_file_size
      t.datetime :audio_updated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :songs
  end
end
