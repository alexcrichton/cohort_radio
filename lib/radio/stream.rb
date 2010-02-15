class Radio
  
  class Stream < Shout
    
    BLOCKSIZE = 1 << 16
    
    @@tag_recoder = Iconv.new("utf-8", 'windows-1251')
    
    attr_accessor :options
    
    def initialize options = {}
      super
      self.options = options
    end
    
    def connect
      return if connected?

      self.host         = options[:host]
      self.port         = options[:port]                        unless options[:port].nil?
      self.user         = options[:user]                        unless options[:user].nil?
      self.pass         = options[:password] || options[:pass]  unless options[:password].nil?
      self.mount        = "/#{options[:playlist].slug}"
      self.name         = options[:playlist].name
      self.description  = options[:playlist].description        if options[:playlist].description
      self.format       = Shout::MP3

      super
      
      @thread = Thread.start {
        loop {
          queue_item = options[:playlist].queue_items.first
          song = queue_item.nil? ? random_song : queue_item.song
        
          m = ShoutMetadata.new
          m.add 'filename', song.audio.path
          m.add 'song', @@tag_recoder.iconv("#{song.title} (#{song.artist} - #{song.album})")
          m.add 'artist', @@tag_recoder.iconv("#{song.artist}")
          m.add 'album', @@tag_recoder.iconv("#{song.album}")

          self.metadata = m
        
          puts "Stream: #{name} - playing file #{song.audio.path}"
        
          begin
            File.open(song.audio.path) do |file|
              while data = file.read(BLOCKSIZE)
                break if @next
              	self.send data
                puts "Stream: #{name} - Block sent"
              	self.sync
              end
            end
            @next = false
          rescue => e
            Rails.logger.error "Stream: #{name} ERROR: #{e}"
            disconnect
          end
        
          options[:playlist].queue_items.delete queue_item if queue_item
        }
      }
    end
    
    def disconnect
      @thread.exit if @thread
      @thread = nil
      super if connected?
    end
    
    def next
      @next = true
    end
    
    private
    def random_song
      ids = Song.select(:id).map &:id
      Song.find(ids[rand(ids.size)])
    end
    
  end
  
end