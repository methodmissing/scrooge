module Scrooge
  module Storage
    class Memory < Base
      
      attr_reader :storage
      
      def initialize
        @storage = {}
      end
      
      def read( tracker )
        @storage[tracker.signature]
      end
                  
      def write( tracker, buffered = true )
        @storage[tracker.signature] = tracker
      end
      
    end
  end
end