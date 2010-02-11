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
        publish parse_message(data)
      end
  
      def supports
        "$Supports BZList TTHL TTHF" # ???
      end
  
    end
  end
end