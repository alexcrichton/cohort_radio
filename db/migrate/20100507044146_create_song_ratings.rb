class CreateSongRatings < ActiveRecord::Migration
  def self.up
    create_table :song_ratings do |t|
      t.integer :user_id
      t.integer :score
      t.integer :song_id

      t.timestamps
    end
    
    add_column :songs, :rating, :float, :default => 0
  end

  def self.down
    drop_table :song_ratings
    remove_column :songs, :ratin
  end
end
