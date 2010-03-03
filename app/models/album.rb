class Album < ActiveRecord::Base
  include Acts::Slug # ugly, I know
  
  acts_with_slug
  
  belongs_to :artist
  has_many :songs
  
  validates_presence_of :name
  
  before_save :get_image, :if => :name_changed?
  
  private
  def get_image
    return if artist.nil? || name.blank?
    album = Scrobbler::Album.new(artist.name, name, :include_info => true) rescue nil
    self[:cover_url] = album.image_large rescue nil if album
  end
  
end