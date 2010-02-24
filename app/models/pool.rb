class Pool < ActiveRecord::Base
  
  belongs_to :playlist
  
  has_and_belongs_to_many :songs
  
end
