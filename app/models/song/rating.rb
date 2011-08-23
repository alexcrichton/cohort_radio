class Song::Rating
  include Mongoid::Document

  field :score, :type => Integer

  belongs_to :song
  belongs_to :user

  validates_presence_of :song, :user

  after_create  :update_song_rating
  after_update  :update_song_rating
  after_destroy :update_song_rating

  scope :for, lambda{ |song| where(:song_id => song.id) }
  scope :by,  lambda{ |user| where(:user_id => user.id) }

  def update_song_rating
    song.update_rating
  end

end
