class IntegrateSongsIntoArtistsAndAlbums < ActiveRecord::Migration
  def self.up
    add_column :songs, :artist_id, :integer
    add_column :songs, :album_id, :integer
  end

  def self.down
    remove_column :songs, :artist_id
    remove_column :songs, :album_id
  end
end
