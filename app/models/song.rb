class Song < ActiveRecord::Base
  
  belongs_to :artist
  belongs_to :album
  has_many :comments, :dependent => :destroy, :order => 'created_at DESC'
  has_many :queue_items, :dependent => :destroy
  has_many :playlists, :through => :queue_items
  has_and_belongs_to_many :pools
  
  validates_presence_of :title
  
  has_attached_file :audio, :path => ":rails_root/private/:class/:attachment/:id/:basename.:extension"
  
  validates_attachment_presence :audio
  validates_attachment_content_type :audio, :content_type => ['audio/mpeg', 'application/x-mp3', 'audio/mp3']
  
  before_create :ensure_artist_and_album
  
  scope :search, Proc.new{ |query| where('title LIKE :q or artists.name LIKE :q or albums.name LIKE :q', :q => "%#{query}%").includes(:artist, :album) }
  
  def ensure_artist_and_album
    if new_record?
      file = audio.queued_for_write[:original].path # get the file paperclip is gonna copy
    else
      file = audio.path
    end

    artist, album = nil, nil
    
    tag = Mp3Info.new(file).tag
    
    unless tag['artist'].blank?
      artist = Artist.find_by_name(tag['artist'])
      artist = Artist.create!(:name => tag['artist']) if artist.nil?
    end
    
    unless tag['album'].blank?
      album = Album.find_by_name(tag['album'])
      if album.nil?
        album = Album.create(:name => tag['album']) 
        album.artist = artist unless artist.blank?
        album.save!
      end
      artist.albums << album unless artist.nil? || artist.albums.include?(album)
    end
    
    self.artist = artist unless artist.nil?
    self.album  = album  unless album.nil?
    self.title  = tag['title'] || File.basename(file)
  end
  
end
