require 'acts_as_slug'

class Playlist < ActiveRecord::Base
  
  acts_with_slug
  
  has_many :queue_items, :order => :priority
  has_many :songs, :through => :queue_items
  has_and_belongs_to_many :users
  
  validates_presence_of :name
  validates_uniqueness_of :name, :if => :name_changed?, :case_sensitive => false
  
end
