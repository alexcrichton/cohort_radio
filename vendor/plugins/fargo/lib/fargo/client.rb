module Fargo
  class Client

    @@after_setup_callbacks = []
    def self.after_setup method
      @@after_setup_callbacks << method
    end
    
    include Fargo::Utils::Publisher
    include Fargo::Supports::Chat
    include Fargo::Supports::Uploads
    include Fargo::Supports::NickList
    include Fargo::Supports::Searches
    include Fargo::Supports::Downloads
    include Fargo::Supports::Persistence
    
    DEFAULTS = {:download_dir => '/tmp/fargo/downloads'}
  
    attr_accessor :options
    
    # Options
    #   :hub_port
    #   :hub_address
    #   :search_port
    #   :active_port
    #   :nick
    #   :password
    #   :email
    #   :speed
    #   :passive
    #   :download_slots
    #   :download_dir
    #   :slots
    def initialize opts = {}
      self.options = DEFAULTS.merge opts
      self.version = '0.75'
      @connection_timeout_threads = {}
    end
  
    # Don't do this in initialization so we have time to set all the options
    def setup
      self.hub = Fargo::Connection::Hub.new options.merge(:client => self, :port => hub_port, :address => hub_address)
      self.searcher = Fargo::Connection::Search.new options.merge(:client => self, :port => search_port, :address => '127.0.0.1') unless passive
      self.active_server = Fargo::ActiveServer.new options.merge(:client => self, :port => active_port, :address => '127.0.0.1') unless passive
      post_setup if respond_to? :post_setup
      
      hub.subscribe{ |type, hash| 
        if type == :connect_with_me && @connection_timeout_threads.has_key?(nick)
          @connection_timeout_threads.delete(nick).exit
        end
        publish type, hash 
      }
      searcher.subscribe{ |*args| publish *args } unless passive
      active_server.subscribe{ |*args| publish *args } unless passive
            
      @@after_setup_callbacks.each{ |callback| send callback }
    end
  
    def get_info nick
      hub.write "$GetINFO #{nick} #{self.nick}"
    end
    
    def get_ip *nicks
      nicks.flatten!
      hub.write "$UserIP #{nicks.join '$$'}"
    end
    
    def connect_with nick
      @connection_timeout_threads[nick] = Thread.start{ sleep 10; connection_timeout! nick }
      
      if passive
        hub.write "$RevConnectToMe #{self.nick} #{nick}"
      else
        hub.write "$ConnectToMe #{nick} #{address}:#{active_port}"
      end
    end
  
    def connect
      setup if options[:hub].nil?
      Fargo.logger.info "Connecting to hub..."
      hub.connect
      searcher.connect unless passive
      active_server.connect unless passive
      Fargo.logger.info "Connected to hub"
    end
    
    def connected?
      options[:hub] && hub.connected?
    end
  
    def disconnect
      return if options[:hub].nil?
      Fargo.logger.info "Disconnecting from hub."
      hub.disconnect
      searcher.disconnect unless passive
      active_server.disconnect unless passive
    end
  
    def search_hub query
      raise ConnectionError.new("Not connected Yet!") if options[:hub].nil?
      hub.write "$Search #{passive ? "Hub:#{nick}" : "#{address}:#{search_port}"} #{query}"
    end
  
    # see hub/parser#@@search for what's passed in
    # searches this client's files based on those options and returns an array of Search::Results
    def search_files options
      []
    end
    
    def method_missing name, *args
      return @options[name.to_s.gsub('=', '').to_sym] = args.shift if name.to_s =~ /=$/
      return @options[name] if args.size == 0 && options.has_key?(name)
      super
    end
    
    def description
      "<++ V:#{version},M:#{passive ? 'P' : 'A'},H:1/0/0,S:#{open_slots},Dt:1.2.0/W>"
    end
    
    private
    def connection_timeout! nick
      @connection_timeout_threads.delete nick
      publish :connection_timeout, :nick => nick
    end
    
  end
end