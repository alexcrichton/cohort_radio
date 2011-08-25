class Song
  include Mongoid::Document

  field :title
  field :album_name
  field :custom_set, :type => Boolean
  field :rating, :type => Float, :default => 0.0
  field :play_count, :type => Integer, :default => 0
  mount_uploader :audio, SongUploader, :validate_integrity => true,
                                       :validate_processing => true

  # Submitted from the form, updated later
  attr_accessor :artist_name

  belongs_to :artist
  embeds_many :ratings, :class_name => 'Song::Rating'

  validates_presence_of :title, :artist
  validates_uniqueness_of :title, :scope => :artist_id,
      :case_sensitive => false, :if => :title_changed?
  validates_presence_of :audio
  validates_integrity_of :audio

  before_validation :ensure_artist_and_album
  validate :unique_title
  after_save :write_metadata

  scope :search, Proc.new{ |query|
    if query.blank?
      where(:id => 0)
    else
      where('title LIKE :q or artists.name LIKE :q or albums.name LIKE :q',
          :q => "%#{query}%").includes(:artist, :album)
    end
  }

  def update_rating
    if ratings.size == 0
      self[:rating] = 0.0
    else
      self[:rating] = ratings.map(&:score).sum.to_f / ratings.size
    end
    save!
  end

  def album
    @album ||= artist.albums.where(:name => album_name).first
  end

  protected

  def ensure_artist_and_album
    return if audio_integrity_error || audio_processing_error
    if !audio.present?
      errors[:audio] << 'is required.'
      return
    end
    file = audio.path

    @old_artist = self.artist

    @artist_name = self.artist.try :name if @artist_name.blank?
    @artist_name ||= audio.artist        if !custom_set
    @artist_name = 'unknown'             if @artist_name.blank?
    self.artist = Artist.where(:name => @artist_name).first ||
                  Artist.create!(:name => @artist_name)

    self[:album_name] ||= audio.album        if !custom_set
    self[:album_name] = 'unknown'            if album_name.blank?
    album.present? or artist.albums.create!(:name => album_name)

    self.title = audio.title unless custom_set
    self.title ||= File.basename(file)
  end

  def write_metadata
    info = Mp3Info.new audio.path
    info.tag['artist'] = @artist_name unless @artist_name == 'unknown'
    info.tag['album']  = album_name   unless  album_name  == 'unknown'
    info.tag['title']  = title
    info.close
  end

  def unique_title
    return if audio_integrity_error || audio_processing_error
    return unless artist.present? && title.present?

    duplicate = Song.where(:title => /#{title}/i).any?{ |s|
      s.artist.name.downcase == artist.name.downcase
    }

    if duplicate
      errors[:audio] << "already exists in database"
    end
  end

end
