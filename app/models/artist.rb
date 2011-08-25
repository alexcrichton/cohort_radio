class Artist
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  slug :name, :index => true

  has_many :songs
  has_many :albums

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :if => :name_changed?

end
