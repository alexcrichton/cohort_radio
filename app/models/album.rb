class Album < ActiveRecord::Base
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
    return if artist.nil? || name.blank?
    album = Scrobbler::Album.new(artist.name, name, :include_info => true) rescue nil
    self[:cover_url] = album.image_large rescue nil if album
  end

end
