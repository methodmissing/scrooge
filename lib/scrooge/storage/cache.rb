module Scrooge
  module Storage
    class Cache < Base
      
      def initialize
        extend Buffer
      end      
      
      # Read from the host framework's cache store.
      #
      def read( tracker )
        profile.framework.read_cache( expand_key( tracker ) )
      end      
      
      # Write to the host framework's cache store.
      #
      def write( tracker, buffered = true )
        profile.framework.write_cache( expand_key( tracker ), tracker )
      end      
      
    end
  end
end