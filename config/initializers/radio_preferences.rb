require File.expand_path('../rails_extensions', __FILE__)
require 'radio/proxy_helper'

ActionController::Base.class_eval { include Radio::ProxyHelper }
ActionView::Base.class_eval       { include Radio::ProxyHelper }
