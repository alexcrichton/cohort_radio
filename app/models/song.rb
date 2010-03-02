class Song < ActiveRecord::Base
  
  belongs_to :artist
  belongs_to :album
  has_many :comments, :dependent => :destroy, :order => 'created_at DESC'
  has_many :queue_items, :dependent => :destroy
  has_many :playlists, :through => :queue_items
  has_and_belongs_to_many :pools
  
  has_attached_file :audio, :path => ":rails_root/private/:class/:attachment/:id/:basename.:extension"
  
  validates_uniqueness_of :title, :scope => [:artist], :if => :title_changed?, :case_sensitive => false
  validates_attachment_presence :audio
  validates_attachment_content_type :audio, :content_type => ['audio/mpeg', 'application/x-mp3', 'audio/mp3']
  
  # before_validation :set_metadata
  
  scope :search, Proc.new{ |query| where('title LIKE :q or artist LIKE :q or album LIKE :q', :q => "%#{query}%") }
  
  def display_title
    if self[:title]
      "#{self[:title]}"
    else
      File.basename audio.path
    end
  end
  
  def self.create_song file
    create_song! file
  rescue ActiveRecord::RecordInvalid
    false
  end
  
  def self.create_song! file
    return false unless File.exists?(file) && File.size(file) > 0
    
    artist, album = nil, nil
    
    tag = Mp3Info.new(file).tag
    
    artist = Artist.find_by_name(tag['artist']) unless tag['artist'].blank?
    album = Album.find_by_name(tag['album']) unless tag['artist'].blank?
    
    artist = Artist.create!(:name => tag['artist']) if artist.nil?
    album = Album.create!(:name => tag['album'], :artist => artist) if album.nil?
    
    artist.albums << album unless artist.albums.include? album
    
    song = Song.create!(:name => tag['title'], :artist => artist, :album => album,
                        :audio => File.new(file))
  end

  # def set_metadata
  #   unless custom_set
  #     if new_record?
  #       file = audio.queued_for_write[:original].path # get the file paperclip is gonna copy
  #     else
  #       file = audio.path
  #     end
  # 
  #     info = Mp3Info.new(file).tag
  #     self[:artist] = info['artist']
  #     self[:album] = info['album']
  #     self[:title] = info['title']
  #   end
  #   return if self[:album].blank? || self[:artist].blank?
  #   album = Scrobbler::Album.new(self[:artist], self[:album], :include_info => true) rescue nil
  #   self[:album_image_url] = album.image_large rescue nil if album
  # end
  
end
