class CreatePools < ActiveRecord::Migration
  def self.up
    create_table :pools, :force => true do |t|
      t.integer :playlist_id

      t.timestamps
    end
    
    create_table :pools_songs, :id => false, :force => true do |t|
      t.integer :pool_id
      t.integer :song_id
    end
    
    Playlist.all.each{ |p| Pool.create! :playlist => p }
  end

  def self.down
    drop_table :pools
  end
end
