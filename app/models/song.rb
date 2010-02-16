class Song < ActiveRecord::Base
  
  has_many :queue_items, :dependent => :destroy
  has_many :playlists, :through => :queue_items
  
  has_attached_file :audio, :path => ":rails_root/private/:class/:attachment/:id/:basename.:extension"
  
  validates_uniqueness_of :title, :scope => [:artist], :if => :title_changed?
  validates_attachment_presence :audio
  validates_attachment_content_type :audio, :content_type => ['audio/mpeg', 'application/x-mp3', 'audio/mp3']
  
  before_validation :set_metadata
  
  def display_title
    if self[:title]
      "#{self[:title]}"
    else
      File.basename audio.path
    end
  end
  
  private
  def set_metadata
    if new_record?
      file = audio.queued_for_write[:original].path # get the file paperclip is gonna copy
    else
      file = audio.path
    end
    return unless Mp3Info.hastag1?(file) || Mp3Info.hastag2?(file)
    info = Mp3Info.new(file).tag
    self[:artist] = info['artist']
    self[:album] = info['album']
    self[:title] = info['title']
    return if self[:album].blank? || self[:artist].blank?
    album = Scrobbler::Album.new(self[:artist], self[:album], :include_info => true)
    self[:album_image_url] = album.image_large
  rescue => e
    Rails.logger.error "Error setting metadata #{e}"
  end
  
end
