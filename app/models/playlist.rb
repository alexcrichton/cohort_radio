class Playlist
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  field :description
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
    url = 'http://music.alexcrichton.com'
    url << ice_mount_point
    url
  end

  protected

  def create_pool
    Pool.create! :playlist => self
  end

end
