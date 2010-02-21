module Fargo
  class Connection
    class Download < Connection
      
      include Fargo::Utils
      include Fargo::Parser
        
      def post_listen
        self[:quit_on_disconnect] = false
        @lock, @pk = generate_lock
        @handshake_step = 0
        @buffer_size = (2 << 12).freeze
        write "$MyNick #{self[:nick]}|$Lock #{@lock} Pk=#{@pk}" if self[:first]
      end
      
      def read_data
        return super if @handshake_step != 6

        data = @socket.read [@buffer_size, @length - @recvd].min

        @file << data
        @recvd += data.length

        if @recvd == @length
          download_finished!
          # disconnect
        else
          publish :download_progress, :percent => @recvd.to_f / @length, :file => download_path, 
                                      :nick => @other_nick, :download => self[:download],
                                      :size => @length
        end
      rescue IOError => e
        Fargo.logger.warn @last_error = "#{self}: IOError, disconnecting #{e}"
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
              self[:client].lock_connection_with! @other_nick, self
              self[:download] = self[:client].lock_next_download! @other_nick, self
              if self[:download].nil? || self[:download].file.nil?
                Fargo.logger.warn @last_error = "Nothing to download from:#{@other_nick}!"
                disconnect
              end
            else
              Fargo.logger.warn @last_error = "Premature disconnect when mynick received"
              disconnect
            end
            
          when :lock
            if @handshake_step == 1
              @remote_lock = message[:lock]
              @handshake_step = 2
              out = ''
              out << "$MyNick #{self[:nick]}|" unless self[:first]
              out << "$Lock #{@lock} Pk=#{@pk}|" unless self[:first]
              out << "$Supports ADCGet|"
              out << "$Direction Download #{@my_num = rand(10000)}|"
              out << "$Key #{generate_key @remote_lock}|"
              write out
            else
              Fargo.logger.warn @last_error = "Premature disconnect when lock received"
              disconnect
            end
            
          when :supports
            if @handshake_step == 2
              @client_extensions = message[:extensions]
              @handshake_step = 3
            else
              Fargo.logger.warn @last_error = "Premature disconnect when supports received"
              disconnect
            end
            
          when :direction
            if @handshake_step == 3 && message[:direction] == 'upload'
              @client_num = message[:number]
              @handshake_step = 4
            else
              Fargo.logger.warn @last_error = "Premature disconnect when direction received"
              disconnect
            end
            
          when :key
            if @handshake_step == 4 && generate_key(@lock) == message[:key]

              dir = File.dirname download_path
              FileUtils.mkdir_p dir unless File.directory? dir

              begin_download!
              
            else
              Fargo.logger.warn @last_error = "Premature disconnect when key received"
              disconnect
            end
          when :file_length, :adcsnd
            if @handshake_step == 5
              @length = message[:size]
              @recvd = 0
              @handshake_step = 6
              write "$Send" unless @client_extensions.include? 'ADCGet'

              publish :download_started, :file => download_path, :download => self[:download], 
                                         :nick => @other_nick   
            else
              Fargo.logger.warn @last_error = "Premature disconnect when #{message[:type]} received"
              disconnect
            end
            
        end
      end
      
      def begin_download!
        @file = File.new(download_path, File::CREAT | File::WRONLY)

        self[:offset] = 0 if self[:offset].nil?

        @file.seek self[:offset]
        @file.sync = true
        
        if @client_extensions.include? 'ADCGet'
          if self[:download].file_list?
            write "$ADCGET file #{self[:download].file} 0 -1"
          else
            write "$ADCGET file #{self[:download].tth.gsub ':', '/'} #{self[:offset]} -1"
          end
        else
          write "$Get #{self[:download].file}$#{self[:offset] + 1}"
        end
        @handshake_step = 5
        @socket.sync = true
        
        Fargo.logger.debug "#{self}: Beginning download of #{self[:download]}"
      end
      
      def download_finished!
        Fargo.logger.debug "#{self}: Finished download of #{self[:download]}"
        
        @file.close
        @socket.sync = false
        
        path, download = download_path, self[:download]
        
        self[:offset] = nil
        @file_path = nil
        self[:download] = nil
        @length = nil
        @recvd = nil
        @handshake_step = 5
        
        publish :download_finished, :file => path, :download => download, :nick => @other_nick
      end
      
      def disconnect
        super

        if !@recvd.nil? || @recvd != @length
          publish :download_failed, :nick => @other_nick, :download => self[:download], 
                                    :file => download_path, :recvd => @recvd, 
                                    :length => @length, :last_error => @last_error
        end
        
        @file.close unless @file.nil? || @file.closed?
      end
  
      def download_path
        return nil if self[:download].nil? || self[:download].file.nil?
        return @file_path unless @file_path.nil?
        prefix = self[:client].download_dir
        filename = File.basename self[:download].file.gsub("\\", '/')
        i = 0

        while File.exists?(@file_path = File.join(prefix, @other_nick, "#{i}-#{filename}"))
          i += 1
        end
        @file_path
      end
  
    end
  end
end