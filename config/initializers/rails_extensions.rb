require 'acts_as_slug'
require 'radio'
require 'push'

ActiveRecord::Base.class_eval { include Acts::Slug }
ActionController::Base.class_eval { include Push::LongPolling }

