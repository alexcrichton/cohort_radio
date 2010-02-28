class MakePlaylistsPrivate < ActiveRecord::Migration
  def self.up
    add_column :playlists, :user_id, :integer
    add_column :playlists, :private, :boolean, :default => false
  end

  def self.down
    remove_column :playlists, :user_id
    remove_column :playlists, :private
  end
end
