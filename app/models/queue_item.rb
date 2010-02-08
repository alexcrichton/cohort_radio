class QueueItem < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :playlist
  belongs_to :song
  
end
