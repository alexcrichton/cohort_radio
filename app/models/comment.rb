class Comment < ActiveRecord::Base
  belongs_to :song
  belongs_to :user
  
  validates_presence_of :song, :user, :text
end
