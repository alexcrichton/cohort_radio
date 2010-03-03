class Artist < ActiveRecord::Base
  include Acts::Slug # ugly, I know
  
  acts_with_slug
  
  validates_uniqueness_of :name, :case_sensitive => false, :if => :name_changed?
  has_many :songs
  has_many :albums, :dependent => :destroy
  
  validates_presence_of :name
  
end
