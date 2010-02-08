class CreateQueueItems < ActiveRecord::Migration
  def self.up
    create_table :queue_items do |t|
      t.integer :song_id
      t.integer :playlist_id
      t.integer :user_id
      t.integer :priority

      t.timestamps
    end
  end

  def self.down
    drop_table :queue_items
  end
end
