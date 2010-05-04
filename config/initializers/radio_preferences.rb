require File.expand_path('../rails_extensions', __FILE__)

ActionController::Base.class_eval { include Radio::ProxyHelper }
ActionView::Base.class_eval       { include Radio::ProxyHelper }
