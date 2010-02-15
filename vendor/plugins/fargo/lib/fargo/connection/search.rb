module Fargo
  class Connection
    class Search < Connection

      def open_socket
        return @socket if @socket
        @socket = UDPSocket.new
        @socket.bind self[:address], self[:port]
        @socket
      end

      def receive(data)
        message = parse_message data
        publish message[:type], message
      end
  
      def supports
        "$Supports BZList TTHL TTHF" # ???
      end
  
    end
  end
end