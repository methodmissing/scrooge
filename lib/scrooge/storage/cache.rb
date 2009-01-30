module Scrooge
  module Storage
    class Cache < Base
      
      def initialize
        extend Buffer
      end      
      
      def read( tracker )
        profile.framework.read_cache( expand_key( tracker ) )
      end      
      
      def write( tracker, buffered = true )
        profile.framework.write_cache( expand_key( tracker ), tracker )
      end      
      
    end
  end
end