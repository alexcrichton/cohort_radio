module Fargo
  class Connection
    class Hub < Connection
  
      include Fargo::Utils
      include Fargo::Parser
      
      def supports
        "$Supports TTHSearch"
      end
  
      # def connect_to_me nick
      #   write "$ConnectToMe #{nick} #{socket.addr[3]}:#{self[:port]}"
      # end
  
      # See <http://www.teamfair.info/DC-Protocol.htm> for specifics on protocol handling
      def receive(data)
        message = parse_message data
        publish message

        case message[:type]
          when :lock 
            @key = generate_key message[:lock]
            write "$Key #{@key}"
          when :hubname
            write "$ValidateNick #{self[:nick]}" unless @validated
          when :hello
            if message[:who] == self[:nick] 
              @validated = true
              write "$Version 1,0091"
              write "$GetNickList"
              write "$MyINFO $ALL #{self[:nick]} #{self[:client].description}$ $#{self[:speed] || 'DSL'}#{self[:status] || 1.chr}$#{self[:email]}$6586992491$"
            end
          when :connect_to_me
            return unless self[:nicks].include?(message[:nick])
            connection = Fargo::Connection::Download.new self.options.merge(message)
            connection.subscribe { |*args| publish *args }
            connection.connect
          when :nick_list
            self[:nicks] = message[:nicks]
          when :op_list
            self[:ops] = message[:nicks]
          when :quit
            self[:nicks].delete message[:who]
            self[:ops].delete message[:who]
          
          # when :privmsg, :chat, :connect_to_me, :denide, :myinfo, :nick_list, :passive_search_result, :badpass, :op_list, :quit, :searchresult, :disconnected, :mystery
          #   publish message[:type], message

          when :getpass
            write "$MyPass #{self[:pass] || ''}"
          when :badpass, :hubfull
            disconnect
          when :passive_search
            return unless self[:nicks].include?(message[:searcher])
            @results = self[:client].search_files message        
            @results.each { |r| write "$SR #{self[:nick]} #{r}" }
          when :active_search
            @results = self[:client].search_files message
            @results.each { |r| r.active_send self[:nick], message[:ip], message[:port] }
          when :revconnect
            # TODO: Don't send RevConnectToMe when we're passive and receiving is passive
            if self[:client].passive?
              write "$RevConnectToMe #{self[:nick]} #{message[:who]}"
            else
              write "$ConnectToMe #{self[:nick]} #{self[:client].address}:#{self[:client].extport}"
            end
        end
      end
    end # Hub
  end # Connection
end # Fargo