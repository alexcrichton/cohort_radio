class Song
  include Mongoid::Document

  field :title
  field :custom_set, :type => Boolean
  mount_uploader :audio, SongUploader

  # Submitted from the form, updated later
  attr_accessor :album_name, :artist_name

  belongs_to :artist
  belongs_to :album
  embeds_many :ratings, :class_name => 'Song::Rating'

  validates_presence_of :title, :artist, :album
  validates_uniqueness_of :title, :scope => :artist_id,
      :case_sensitive => false, :if => :title_changed?
  validate :unique_title

  validates_presence_of :audio
  validates_integrity_of :audio

  before_validation :ensure_artist_and_album
  validate :unique_title
  after_save :destroy_stale_artist_and_album
  after_save :write_metadata
  after_destroy :destroy_invalid_artist_and_album

  scope :search, Proc.new{ |query|
    if query.blank?
      where(:id => 0)
    else
      where('title LIKE :q or artists.name LIKE :q or albums.name LIKE :q',
          :q => "%#{query}%").includes(:artist, :album)
    end
  }

  def rating
    ratings.size == 0 ? 0 : ratings.map(&:score).sum.to_f / ratings.size
  end

  protected

  def ensure_artist_and_album
    if !audio.present?
      errors[:audio] << "is required."
      return
    end
    file = audio.path

    artist, album = nil, nil

    @artist_name = self.artist.try :name if @artist_name.blank?
    @artist_name ||= audio.artist        if !custom_set
    @artist_name = 'unknown'             if @artist_name.blank?
    artist = Artist.where(:name => @artist_name).first ||
             Artist.create!(:name => artist_name)

    @album_name = self.album.try :name if @album_name.blank?
    @album_name ||= audio.album        if !custom_set
    @album_name = 'unknown'            if @album_name.blank?
    album = artist.albums.where(:name => album_name).first ||
            Album.create!(:name => album_name, :artist => artist)

    @old_artist = self.artist
    self.artist = artist

    @old_album = self.album
    self.album = album

    self.title = audio.title unless custom_set
    self.title ||= File.basename(file)
  end

  def destroy_stale_artist_and_album
    @old_artist.destroy if @old_artist && @old_artist.id != artist.id && @old_artist.songs.size == 0
    @old_album.destroy  if @old_album  && @old_album.id  != album.id  && @old_album.songs.size  == 0
  end

  def write_metadata
    info = Mp3Info.new audio.path
    info.tag['artist'] = artist.name unless artist.name == 'unknown'
    info.tag['album']  = album.name  unless album.name  == 'unknown'
    info.tag['title']  = title
    info.close
  end

  def destroy_invalid_artist_and_album
    album.destroy  if album.songs.size  == 0
    artist.destroy if artist.songs.size == 0
  end

  protected

  def unique_title
    return unless artist.present? && title.present?

    duplicate = Song.where(:title => /#{title}/i).any?{ |s|
      s.artist.name.downcase == artist.name.downcase
    }

    if duplicate
      errors[:audio] << "already exists in database."
    end
  end

end
