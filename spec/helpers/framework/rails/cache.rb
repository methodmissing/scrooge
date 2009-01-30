module Spec
  module Helpers
    module Framework
      module Rails
        class Cache
          
          attr_reader :storage
          
          def initialize
            @storage = {}
          end
          
          def read( key )
            @storage[key]
          end
          
          def write( key, value )
            @storage[key] = value
          end
          
        end
      end
    end
  end
end