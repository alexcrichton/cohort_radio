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

  validates_processing_of :audio, :on => :create
  validates_integrity_of :audio, :on => :create
  before_validation :ensure_artist_and_album
  validate :unique_title
  after_save :write_metadata

  scope :search, Proc.new{ |query|
    if query.blank?
      where(:id => 0)
    else
      query = Regexp.escape query
      any_of({:title => /#{query}/i}, {:artist_name => /#{query}/i},
             {:album_name => /#{query}/i})
    end
  }

  protected

  def ensure_artist_and_album
    return if audio_integrity_error || audio_processing_error
    if !audio.present? && new_record?
      errors[:audio] << 'is required.'
      return
    end
    file = audio.path

    art = artist_name
    art = self.artist.try :name if art.blank?
    art ||= audio.artist        if !custom_set
    art = 'unknown'             if art.blank?
    self.artist = Artist.where(:name => art).first ||
                  Artist.create!(:name => art)

    alb = album_name
    alb = self.album.try :name if alb.blank?
    alb ||= audio.album        if !custom_set
    alb = 'unknown'            if alb.blank?
    self.album = artist.albums.where(:name => alb).first ||
                 artist.albums.create!(:name => alb)

    self.artist_name = art
    self.album_name  = alb
    self.title ||= audio.title unless custom_set
    self.title ||= File.basename(file)
  end

  def write_metadata
    Resque.enqueue WriteMetadata, id
  end

  def unique_title
    return if audio_integrity_error || audio_processing_error
    return unless artist.present? && title.present?

    name = Regexp.escape title
    duplicate = Song.where(:title => /#{name}/i).any?{ |s|
      s.artist_name.downcase == artist_name.downcase
    }

    if duplicate
      errors[:audio] << "already exists in database"
    end
  end

end
