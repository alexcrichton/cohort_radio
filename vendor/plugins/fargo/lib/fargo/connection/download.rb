module Fargo
  class Connection
    class Download < Connection
      
      include Fargo::Utils
      include Fargo::Parser
        
      def pre_listen
        self[:quit_on_disconnect] = false
        @lock, @pk = generate_lock
        @handshake_step = 0
        @buffer_size = (2 << 12).freeze
      end
      
      def post_listen
        write "$MyNick #{self[:nick]}|$Lock #{@lock} Pk=#{@pk}" if self[:first]
      end
      
      
      def read_data
        return super if @handshake_step != 6

        @exit_time = 20
        
        length = @buffer_size < @length - @recvd ? @buffer_size : @length - @recvd
        data = @socket.read length
        
        if @zlib
          @zs = Zlib::Inflate.new if @zs.nil?
          data = @zs.inflate data
        end
        
        @file << data
        @recvd += data.length

        if @recvd == @length
          download_finished!
        else
          publish :download_progress, :percent => @recvd.to_f / @length, :file => download_path, 
                                      :nick => @other_nick, :download => self[:download],
                                      :size => @length, :compressed => @zlib
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

              self[:client].connected_with! @other_nick
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
              out << "$Supports TTHF ADCGet ZLIG|"
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
              @recvd = 0
              @handshake_step = 6
              
              @zlib = message[:zlib]
              @length = message[:size]
              
              @exit_time = 20
              @exit_thread = Thread.start { 
                while @exit_time > 0
                  sleep 1
                  @exit_time -= 1
                end
                download_timeout! 
              }

              write "$Send" unless @client_extensions.include? 'ADCGet'
              
              publish :download_started, :file => download_path, :download => self[:download], 
                                         :nick => @other_nick   
            else
              Fargo.logger.warn @last_error = "Premature disconnect when #{message[:type]} received"
              disconnect
            end
          when :noslots
            if self[:download]
              Fargo.logger.debug "#{self}: No Slots for #{self[:download]}"

              path, download = download_path, self[:download]

              reset_download

              publish :download_failed, :nick => @other_nick, :download => download, 
                                        :file => path, :last_error => "No slots!"
            end
          when :error
            Fargo.logger.error "#{self}: Error! #{message[:message]}"
            disconnect
        end
      end
      
      def begin_download!
        @file = File.new(download_path, File::CREAT | File::WRONLY)

        self[:offset] = 0 if self[:offset].nil?

        @file.seek self[:offset]
        @file.sync = true
        
        if @client_extensions.include? 'ADCGet'
          download_query = self[:download].file
          if !self[:download].file_list? && @client_extensions.include?('TTHF')
            download_query = self[:download].tth.gsub ':', '/'
          end
          zlig = ''
          if @client_extensions.include?("ZLIG") 
            zlig = "ZL1"
            Fargo.logger.debug "#{self} Enabling zlib compression on: #{self[:download].file}"
          end
          write "$ADCGET file #{download_query} 0 -1 #{zlig}"
        else
          write "$Get #{self[:download].file}$#{self[:offset] + 1}"
        end
        @handshake_step = 5
        @socket.sync = true
        
        Fargo.logger.debug "#{self}: Beginning download of #{self[:download]}"
      end
      
      def download_timeout!
        Fargo.logger.debug "#{self}: Timeout of #{self[:download]}"
        
        path, download = download_path, self[:download]

        reset_download
        
        publish :download_failed, :nick => @other_nick, :download => download, 
                                  :file => path, :last_error => "Download timeout!"
      end
      
      def download_finished!
        Fargo.logger.debug "#{self}: Finished download of #{self[:download]}"
        
        path, download = download_path, self[:download]
        
        reset_download
        
        publish :download_finished, :file => path, :download => download, :nick => @other_nick
      end
      
      def disconnect
        super

        if self[:download]
          publish :download_failed, :nick => @other_nick, :download => self[:download], 
                                    :file => download_path, :recvd => @recvd, 
                                    :length => @length, :last_error => @last_error
        end
        
        reset_download
      end
     
      private
      def reset_download
        @file.close unless @file.nil? || @file.closed?
        @socket.sync = false if @socket
        
        @exit_thread.exit if @exit_thread.alive?
        
        @zs = self[:offset] = @file_path = @zlib = self[:download] = @length = @recvd = nil        

        @handshake_step = 5
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