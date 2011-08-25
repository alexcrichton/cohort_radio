class User
  include Mongoid::Document
  devise :rememberable

  field :token
  field :name
  index :token

end
