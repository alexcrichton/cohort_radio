class AddUsersToPlaylists < ActiveRecord::Migration
  def self.up
    create_table :playlists_users, :id => false, :force => true do |t|
      t.integer :playlist_id
      t.integer :user_id
    end
  end

  def self.down
    drop_table :playlists_users
  end
end
