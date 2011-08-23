class Artist
  include Mongoid::Document

  field :name
  field :slug
  index :slug

  has_many :songs
  has_many :albums, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :if => :name_changed?

  before_validation :create_slug

  def to_param
    self[:slug]
  end

  protected

  def create_slug
    self[:slug] = self[:name].parameterize
  end

end
