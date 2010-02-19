require 'socket'
require 'base64'
require 'thread'
require 'logger'
require 'fileutils'

require File.dirname(__FILE__) + '/fargo/utils'
require File.dirname(__FILE__) + '/fargo/utils/publisher'
require File.dirname(__FILE__) + '/fargo/parser'
require File.dirname(__FILE__) + '/fargo/search'
require File.dirname(__FILE__) + '/fargo/search/result'

require File.dirname(__FILE__) + '/fargo/handler/chat'
require File.dirname(__FILE__) + '/fargo/handler/searches'
require File.dirname(__FILE__) + '/fargo/handler/nick_list'
require File.dirname(__FILE__) + '/fargo/handler/download_manager'

require File.dirname(__FILE__) + '/fargo/connection'
require File.dirname(__FILE__) + '/fargo/connection/download'
require File.dirname(__FILE__) + '/fargo/connection/hub'
require File.dirname(__FILE__) + '/fargo/connection/search'
require File.dirname(__FILE__) + '/fargo/connection/upload'

require File.dirname(__FILE__) + '/fargo/client'
require File.dirname(__FILE__) + '/fargo/active_server'

Thread.abort_on_exception = true

module Fargo
  class ConnectionException < RuntimeError; end
  
  
  @@logger = Logger.new STDOUT
  
  def self.logger
    @@logger
  end
  
  def self.logger= logger
    @@logger = logger
  end
  
end