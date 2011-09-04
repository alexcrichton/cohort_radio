class Playlist
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  field :description
  field :playing, :type => Boolean
  field :current_song
  slug :name, :index => true

  embeds_many :queue_items
  embeds_one :pool

  after_create :create_pool

  validates_presence_of :name
  validates_uniqueness_of :name, :if => :name_changed?, :case_sensitive => false

  def ice_mount_point
    return "/#{slug}" if Rails.env.production?
    "/#{slug}-#{Rails.env}"
  end

  def ice_name
    return "Cohort Radio - #{name}" if Rails.env.production?
    "#{name} - #{Rails.env}"
  end

  def stream_url
    "http://music.alexcrichton.com#{ice_mount_point}"
  end

  def random_song
    if pool.song_ids.present? && pool.song_ids.count > 0
      Song.find pool.song_ids.sample
    else
      Song.scoped.offset(rand(Song.count)).first
    end
  end

  protected

  def create_pool
    Pool.create! :playlist => self
  end

end
