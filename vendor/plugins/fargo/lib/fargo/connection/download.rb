module Fargo
  class Connection
    class Download < Connection
      
      include Fargo::Utils
      include Fargo::Parser
        
      def post_listen
        @lock, @pk = generate_lock
        @handshake_step = 0
        @buffer_size = 2 << 12
        write "$MyNick #{self[:nick]}"
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
          publish :download_finished, :file => download_path, :remote_file => self[:file], :nick => @other_nick
          disconnect
        else
          publish :download_progress, :percent => @recvd.to_f / @length, :file => download_path, :nick => @other_nick, :remote_file => self[:file]
        end
      rescue IOError
        Fargo.logger.warn "#{self}: IOError, disconnecting"
        disconnect
      end
  
      def receive data
        message = parse_message data
        publish message[:type], message
        
        case message[:type]
          when :mynick
            if @handshake_step == 0
              @handshake_step = 1 
              @other_nick = message[:nick]
              self[:file] = self[:client].downloading[@other_nick].shift
              if self[:file].nil?
                Fargo.logger.warn "Nothing to download from:#{@other_nick}!"
                disconnect
              end
            else
              Fargo.logger.warn "Premature disconnect when mynick received"
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
              Fargo.logger.warn "Premature disconnect when lock received"
              disconnect
            end
          when :supports
            if @handshake_step == 2
              @client_extensions = message[:extensions]
              @handshake_step = 3
            else
              Fargo.logger.warn "Premature disconnect when supports received"
              disconnect
            end
          when :direction
            if @handshake_step == 3 && message[:direction] == 'upload'
              @client_num = message[:number]
              @handshake_step = 4
            else
              Fargo.logger.warn "Premature disconnect when direction received"
              disconnect
            end
          when :key
            if @handshake_step == 4 && generate_key(@lock) == message[:key]

              dir = File.dirname download_path
              FileUtils.mkdir_p dir unless File.directory? dir

              @file = File.new(download_path, File::CREAT | File::WRONLY)

              @file.seek self[:offset] || 0
              @file.sync = true
              
              write "$Get #{self[:file]}$#{self[:offset] || 1}"
              @handshake_step = 5
            else
              Fargo.logger.warn "Premature disconnect when key received"
              disconnect
            end
          when :file_length
            if @handshake_step == 5
              @length = message[:length]
              @recvd = 0
              @handshake_step = 6
              publish :download_started, :file => download_path, :remote_file => self[:file], :nick => @other_nick   
              write "$Send"
            else
              Fargo.logger.warn "Premature disconnect when file_length received"
              disconnect
            end
        end
      end
      
      def disconnect
        if @recvd.nil? || @recvd != @length
          publish :download_failed, :nick => @other_nick, :remote_file => self[:file], :file => download_path 
          @file.close unless @file.nil? || @file.closed?
        end
        super
      end
  
      def download_path
        return nil if self[:file].nil?
        return @file_path unless @file_path.nil?
        prefix = self[:client].download_dir
        filename = File.basename self[:file].gsub("\\", '/')
        i = 0

        while File.exists?(@file_path = File.join(prefix, @other_nick, "#{i}-#{filename}"))
          i += 1
        end
        @file_path
      end
  
    end
  end
end