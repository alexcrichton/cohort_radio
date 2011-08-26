class QueueItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :priority, :type => Float

  embedded_in :playlist
  belongs_to :song
  belongs_to :user

  scope :ordered, order_by(:priority.asc, :created_at.asc)

  def enqueue!
    items = playlist.queue_items.reject{ |i| i == self }
    ids   = items.map(&:user_id)
    index = index_to_insert user.id, ids

    pl = index < items.size ? items[index].priority : 0
    pr = index + 1 < items.size ? items[index + 1].priority : pl + 128

    self[:priority] = (pl + pr) / 2
    save!
  end

  protected

  def index_to_insert id, ids
    last = (ids.rindex(id) || -1) + 1
    if last == ids.length
      last
    else
      n = ids[(last + 1)..-1].index ids[last]
      n ? n + last : last
    end
  end

end
