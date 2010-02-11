module Fargo
  module Management
    module Utils
      
      def encode args
        data = Base64.encode64 Marshal.dump(args)
        data << "\005"
        data
      end
      
      def decode data
        data = data.chomp "\005"
        Marshal.load Base64.decode64(data)
      end
    end
  end
end
