class QueueItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :priority, :type => Integer

  embedded_in :playlist
  belongs_to :song
  belongs_to :user

  scope :ordered, order_by(:priority.asc, :created_at.asc)

  def enqueue!
    items = playlist.queue_items.reject{ |i| i == self }
    if items.size == 0
      self[:priority] = 0
      save!
      return
    end

    ids = items.map(&:user_id)
    index = index_to_insert user.id, ids

    pl = index < items.size ? items[index].priority : 0
    pr = index + 1 < items.size ? items[index + 1].priority : pl + 128

    self[:priority] = pl / 2 + pr / 2
    save!
  end

  protected

  def index_to_insert id, ids
    return 0 if ids.length == 0

    last = 0
    for i in 1..ids.length - 1 do
      last = i if ids[i] == id
    end
    l, r = last + 1, ids.length - 1
    while l < r
      arr = ids[l..r]
      u = arr.shift
      n = arr.index(u)
      if n.nil?
        l = r
      else
        r = l + n
      end
    end

    (l + r) / 2
  end

end
