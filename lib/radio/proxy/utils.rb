class Radio
  module Proxy
    module Utils
      
      DELIM = "\005"
      
      def encode arg
        data = Base64.encode64 Marshal.dump(arg)
        data << DELIM
        data
      end
      
      def decode data
        data = data.chomp DELIM
        Marshal.load Base64.decode64(data)
      rescue TypeError
        nil
      end
      
    end
  end
end
