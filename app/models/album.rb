class Album
  include Mongoid::Document

  field :name
  field :slug
  field :cover_url
  index :slug

  belongs_to :artist
  has_many :songs

  validates_presence_of :name, :artist
  validates_uniqueness_of :name, :scope => :artist_id, :case_sensitive => false,
    :if => :name_changed?

  before_save :get_image, :if => :name_changed?
  before_validation :set_slug

  def to_param
    self[:slug]
  end

  private

  def set_slug
    self[:slug] = self[:name].parameterize
  end

  def get_image
    Resque.enqueue ScrobbleAlbum, id
  end

end
