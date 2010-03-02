class CreateAlbums < ActiveRecord::Migration
  def self.up
    create_table :albums do |t|
      t.string :name
      t.string :slug
      t.string :cover_url
      t.integer :artist_id

      t.timestamps
    end
    
    add_index :albums, :slug
  end

  def self.down
    drop_table :albums
  end
end
