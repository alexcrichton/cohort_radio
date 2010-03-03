class Artist < ActiveRecord::Base
  include Acts::Slug # ugly, I know
  
  acts_with_slug
  
  has_many :songs
  has_many :albums
  
  validates_presence_of :name
  
end