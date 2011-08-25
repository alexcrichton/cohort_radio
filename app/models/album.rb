class Album
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  field :cover_url
  slug :name, :index => true

  belongs_to :artist
  has_many :songs

  validates_presence_of :name, :artist
  validates_uniqueness_of :name, :scope => :artist_id, :case_sensitive => false,
    :if => :name_changed?

  before_save :get_image, :if => :name_changed?

  private

  def get_image
    Resque.enqueue ScrobbleAlbum, artist.id, id
  end

end
