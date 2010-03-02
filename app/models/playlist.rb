require 'acts_as_slug'

class Playlist < ActiveRecord::Base
  
  include Acts::Slug # ugly, I know
  
  acts_with_slug
  
  has_many :queue_items, :order => 'priority ASC, created_at ASC', :dependent => :destroy
  has_many :songs, :through => :queue_items

  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  
  belongs_to :user
  
  has_one :pool, :dependent => :destroy
  
  after_create :create_pool
  
  validates_presence_of :name
  validates_uniqueness_of :name, :if => :name_changed?, :case_sensitive => false
    
  def ice_mount_point
    return "/#{slug}" if Rails.env.production?
    "/#{slug}-#{Rails.env}"
  end
  
  def ice_name
    return "#{name}" if Rails.env.production?
    "#{name} - #{Rails.env}"
  end
  
  def stream_url
    url = "http://"
    url << Radio::DEFAULTS[:stream_user]
    url << ':'
    url << Radio::DEFAULTS[:stream_password]
    url << '@'
    url << Radio::DEFAULTS[:remote_host]
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
  
  private
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
