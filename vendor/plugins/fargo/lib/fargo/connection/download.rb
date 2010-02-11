module Fargo
  class Connection
    class Download < Connection
      
      include Fargo::Utils
      include Fargo::Parser
        
      def post_listen
        @lock, @pk = generate_lock
        @handshake_step = 0
        @buffer_size = 2 << 12
        write "$MyNick #{self[:nick]}" #"|$Lock #{@lock} Pk=#{@pk}"
      end
      
      # TODO: actually support some of these
      def supports
        "$Supports MiniSlots XmlBZList ADCGet TTHL TTHF ZLIG" # ???
      end
      
      def read_data
        return super if @handshake_step != 6
        data = @socket.sysread [@buffer_size, @length - @recvd].min
        @file << data
        @recvd += data.length
        if @recvd == @length
          @file.close
          publish :type => :download_finished, :file => @filename
          disconnect
        else
          publish :type => :download_progress, :percent => @recvd.to_f / @length
        end
      rescue IOError
        disconnect
      end
  
      def receive(data)
        message = parse_message data
        publish message
        case message[:type]
          when :mynick
            if @handshake_step == 0
              @handshake_step = 1 
              @other_nick = message[:nick]
            else
              disconnect
            end
          when :lock
            if @handshake_step == 1
              @remote_lock = message[:lock]
              @handshake_step = 2
              write "$Lock #{@lock} Pk=#{@pk}"
              write supports
              write "$Direction Download #{@my_num = rand(10000)}"
              write "$Key #{generate_key @remote_lock}"
            else
              disconnect
            end
          when :supports
            if @handshake_step == 2
              @client_extensions = message[:extensions]
              @handshake_step = 3
            else
              disconnect
            end
          when :direction
            if @handshake_step == 3 && message[:direction] == 'upload'
              @client_num = message[:number]
              @handshake_step = 4
            else
              disconnect
            end
          when :key
            if @handshake_step == 4 && generate_key(@lock) == message[:key]
              @filename = self[:client].downloading[@other_nick].first
              @file = File.new(File.expand_path("~/#{File.basename(@filename.gsub("\\", '/'))}"), File::CREAT | File::WRONLY)
              @file.seek options[:offset] || 0
              @file.sync = true
              
              write "$Get #{@filename}$#{self[:offset] || 1}"
              @handshake_step = 5
            else
              disconnect
            end
          when :file_length
            if @handshake_step == 5
              @length = message[:length]
              @recvd = 0
              @handshake_step = 6
              write "$Send"
            else
              disconnect
            end
        end
      end
  
    end
  end
end