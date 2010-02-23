require 'acts_as_slug'

class Playlist < ActiveRecord::Base
  
  include Acts::Slug # ugly, I know
  
  acts_with_slug
  
  has_many :queue_items, :order => 'priority ASC, created_at ASC'
  has_many :songs, :through => :queue_items
  has_and_belongs_to_many :users
  
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
    # ids = items.map &:user_id
    # last = 0
    # for i in 1..ids.length-1 do
    #   last = i if ids[i] == user.id
    # end
    items.create :song => song, :user => user
  end
  
end
