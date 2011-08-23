class User
  include Mongoid::Document
  devise :rememberable

  field :token
  index :token

  # has_many :queue_items, :dependent => :destroy
  # has_many :memberships, :dependent => :destroy
  # has_many :playlists, :through => :memberships

  # validates_presence_of :name
  # validates_uniqueness_of :name, :case_sensitive => false
  #
  # attr_accessible :name, :email, :password, :password_confirmation

  scope :admins, where(:admin => true)
  scope :search, Proc.new{ |query|
    if query.blank?
      where(:id => 0)
    else
      where('name LIKE :q or email LIKE :q', :q => "%#{query}%")
    end
  }
end
