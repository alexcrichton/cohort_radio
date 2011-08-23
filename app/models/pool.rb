class Pool
  include Mongoid::Document
  field :song_ids, :type => Array

  embedded_in :playlist
end
