class Song::Rating < ActiveRecord::Base
  belongs_to :song
  belongs_to :user
  
  validates_presence_of :song, :user
  
  after_create :update_song_rating
  after_destroy :update_song_rating
  
  def update_song_rating
    song.update_rating
  end
  
end
