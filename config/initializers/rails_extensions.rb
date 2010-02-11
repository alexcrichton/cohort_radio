require 'acts_as_slug'
require 'push'

ActiveRecord::Base.class_eval { include Acts::Slug }
ActionController::Base.class_eval { include Push::LongPolling }

