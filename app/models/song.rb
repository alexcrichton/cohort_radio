class Song < ActiveRecord::Base
  
  has_many :queue_items, :dependent => :destroy
  has_many :playlists, :through => :queue_items
  
  has_attached_file :audio, :path => ":rails_root/private/:class/:attachment/:id/:basename.:extension"
  validates_attachment_presence :audio
  validates_attachment_content_type :audio, :content_type => ['audio/mpeg', 'application/x-mp3', 'audio/mp3']
  after_post_process :post_process_audio

  private
  def post_process_audio
    file = audio.queued_for_write[:original].path
    return unless Mp3Info.hastag1?(file)
    info = Mp3Info.new(file).tag
    self[:artist] = info['artist']
    self[:album] = info['album']
    self[:title] = info['title']
    return if self[:album].blank? || self[:artist].blank?
    album = Scrobbler::Album.new(self[:artist], self[:album], :include_info => true)
    self[:album_image_url] = album.image_large
  end
  
end
