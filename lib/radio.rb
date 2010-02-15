class Radio
    
  DEFAULTS = {:user => 'source', :password => 'hackme', :host => 'localhost', :port => 8000}
  
  attr_accessor :options
  
  def initialize options = {}
    self.options = DEFAULTS.merge options
    @streaming = {}
    @connected = false
  end
  
  def connect
    @streaming.each_value { |stream| stream.connect }
    @connected = true
  end
  
  def disconnect
    @streaming.each_value { |stream| stream.disconnect }
    @connected = false
  end
  
  def add_playlist playlist
    return if @streaming[playlist.slug]
    stream = Radio::Stream.new options.merge(:playlist => playlist)
    @streaming[playlist.slug] = stream      
    stream.connect if @connected
  end
  
  def remove_playlist playlist
    return unless @streaming.has_key? playlist.slug
    @streaming.delete(playlist.slug).disconnect
  end
  
end
