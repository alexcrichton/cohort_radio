class CreateArtists < ActiveRecord::Migration
  def self.up
    create_table :artists do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    
    add_index :artists, :slug
  end

  def self.down
    drop_table :artists
  end
end
