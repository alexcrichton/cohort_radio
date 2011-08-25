class Song
  include Mongoid::Document

  field :title
  field :album_name
  field :artist_name
  field :custom_set, :type => Boolean
  field :play_count, :type => Integer, :default => 0
  mount_uploader :audio, SongUploader

  belongs_to :album
  belongs_to :artist

  validates_presence_of :title, :artist
  validates_uniqueness_of :title, :scope => :artist_id,
      :case_sensitive => false, :if => :title_changed?

  validates_processing_of :audio
  validates_integrity_of :audio
  before_validation :ensure_artist_and_album
  validate :unique_title
  after_save :write_metadata

  scope :search, Proc.new{ |query|
    if query.blank?
      where(:id => 0)
    else
      any_of({:title => /#{query}/i}, {:artist_name => /#{query}/i},
             {:album_name => /#{query}/i})
    end
  }

  protected

  def ensure_artist_and_album
    return if audio_integrity_error || audio_processing_error
    if !audio.present?
      errors[:audio] << 'is required.'
      return
    end
    file = audio.path

    artist_name = self.artist.try :name if artist_name.blank?
    artist_name ||= audio.artist        if !custom_set
    artist_name = 'unknown'             if artist_name.blank?
    self.artist = Artist.where(:name => artist_name).first ||
                  Artist.create!(:name => artist_name)

    album_name = self.album.try :name if album_name.blank?
    album_name ||= audio.album        if !custom_set
    album_name = 'unknown'             if album_name.blank?
    self.album = artist.albums.where(:name => album_name).first ||
                 artist.albums.create!(:name => album_name)

    self.artist_name = artist_name
    self.album_name  = album_name
    self.title ||= audio.title unless custom_set
    self.title ||= File.basename(file)
  end

  def write_metadata
    Resque.enqueue WriteMetadata, id
  end

  def unique_title
    return if audio_integrity_error || audio_processing_error
    return unless artist.present? && title.present?

    duplicate = Song.where(:title => /#{title}/i).any?{ |s|
      s.artist_name.downcase == artist_name.downcase
    }

    if duplicate
      errors[:audio] << "already exists in database"
    end
  end

end
