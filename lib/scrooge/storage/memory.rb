module Scrooge
  module Storage
    class Memory < Base
      
      attr_reader :storage
      
      def initialize
        @storage = {}
      end
      
      def read( tracker )
        GUARD.synchronize do
          @storage[tracker.signature]
        end
      end
                  
      def write( tracker, buffered = true )
        GUARD.synchronize do
          @storage[tracker.signature] = tracker
        end
      end
      
    end
  end
end