class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :albums, :artist_id
    add_index :playlists, :slug
    add_index :queue_items, :playlist_id
    add_index :queue_items, :song_id
    add_index :song_ratings, :song_id
    add_index :songs, :album_id
    add_index :songs, :artist_id
  end

  def self.down
    remove_index :songs, :artist_id
    remove_index :songs, :album_id
    remove_index :song_ratings, :song_id
    remove_index :queue_items, :song_id
    remove_index :queue_items, :playlist_id
    remove_index :playlists, :slug
    remove_index :albums, :artist_id
  end
end