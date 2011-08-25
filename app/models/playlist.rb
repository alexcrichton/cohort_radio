class Playlist
  include Mongoid::Document
  include Mongoid::Slug

  field :name
  field :description
  slug :name, :index => true

  embeds_many :queue_items
  embeds_one :pool

  after_create :create_pool

  validates_presence_of :name
  validates_uniqueness_of :name, :if => :name_changed?, :case_sensitive => false

  def ice_mount_point
    return "/#{slug}" if Rails.env.production?
    "/#{slug}-#{Rails.env}"
  end

  def ice_name
    return "Cohort Radio - #{name}" if Rails.env.production?
    "#{name} - #{Rails.env}"
  end

  def stream_url
    url = 'http://music.alexcrichton.com'
    url << ice_mount_point
    url
  end

  def enqueue song, user
    items = self.queue_items
    return items.create :song => song, :user => user, :priority => 0 if items.size == 0
    ids = items.map &:user_id

    index = index_to_insert user.id, ids

    pl = index < items.size ? items[index].priority : 0
    pr = index + 1 < items.size ? items[index + 1].priority : pl + 128

    items.create :song => song, :user => user, :priority => (pl / 2 + pr / 2)
  end

  protected

  def index_to_insert id, ids
    return 0 if ids.length == 0

    last = 0
    for i in 1..ids.length - 1 do
      last = i if ids[i] == id
    end
    l, r = last + 1, ids.length - 1
    while l < r
      arr = ids[l..r]
      u = arr.shift
      n = arr.index(u)
      if n.nil?
        l = r
      else
        r = l + n
      end
    end

    (l + r) / 2
  end

  def create_pool
    Pool.create! :playlist => self
  end

end
