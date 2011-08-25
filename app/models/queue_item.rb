class QueueItem
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embedded_in :playlist
  belongs_to :song

  scope :ordered, order_by(:priority.asc, :created_at.asc)

end
