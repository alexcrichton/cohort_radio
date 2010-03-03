class Song < ActiveRecord::Base
  
  attr_accessor :album_name, :artist_name
  
  belongs_to :artist
  belongs_to :album
  has_many :comments, :dependent => :destroy, :order => 'created_at DESC'
  has_many :queue_items, :dependent => :destroy
  has_many :playlists, :through => :queue_items
  has_and_belongs_to_many :pools
  
  validates_presence_of :title, :artist
  validates_uniqueness_of :title, :scope => :artist_id, :if => :title_changed?
  
  has_attached_file :audio, :path => ":rails_root/private/:class/:attachment/:id/:basename.:extension"
  
  validates_attachment_presence :audio
  validates_attachment_content_type :audio, :content_type => ['audio/mpeg', 'application/x-mp3', 'audio/mp3']
  
  before_validation :ensure_artist_and_album
  after_save :destroy_stale_artist_and_album
  
  scope :search, Proc.new{ |query| where('title LIKE :q or artists.name LIKE :q or albums.name LIKE :q', :q => "%#{query}%").includes(:artist, :album) }
  
  def ensure_artist_and_album
    if new_record?
      file = audio.queued_for_write[:original].path # get the file paperclip is gonna copy
    else
      file = audio.path
    end

    artist, album = nil, nil
    
    tag = Mp3Info.new(file).tag
    
    self.artist_name ||= tag['artist'] unless custom_set
    
    unless artist_name.blank?
      artist = Artist.find_by_name artist_name
      artist = Artist.new(:name => artist_name) if artist.nil?
    end
    
    self.album_name ||= tag['album'] unless custom_set
    
    unless album_name.blank?
      album = artist.albums.find_by_name album_name
      album = Album.new(:name => album_name, :artist => artist) if album.nil?
    end
    
    @old_artist = self.artist
    self.artist = artist unless artist.nil?

    @old_album =  self.album
    self.album =  album  unless album.nil?
    
    self.title ||= File.basename(file)
    self.title =   tag['title'] unless custom_set
  end
  
  def destroy_stale_artist_and_album
    @old_artist.destroy if @old_artist && @old_artist.id != artist.id && @old_artist.songs.size == 0
    @old_album.destroy  if @old_album  && @old_album.id  != album.id  && @old_album.songs.size  == 0
  end
  
end
