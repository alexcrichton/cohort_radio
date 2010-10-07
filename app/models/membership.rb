class Membership < ActiveRecord::Base

  belongs_to :playlist
  belongs_to :user

  validates_presence_of :playlist, :user

end
