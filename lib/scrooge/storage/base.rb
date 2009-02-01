module Scrooge
  module Storage
    
    autoload :Buffer, 'scrooge/storage/buffer'
    autoload :FileSystem, 'scrooge/storage/file_system'
    autoload :Memory, 'scrooge/storage/memory'
    autoload :Cache, 'scrooge/storage/cache'
    
    class Base < Scrooge::Base
      class NotImplemented < StandardError
      end 
      
      NAMESPACE = 'scrooge_storage'.freeze 
          
      class << self
        
        def instantiate( storage_signature )
          "::Scrooge::Storage::#{storage_signature.to_const}".to_const!
        end
        
      end    
      
      def initialize
        extend Buffer
      end
                       
      def read( tracker )
        raise NotImplemented
      end      
            
      def write( tracker, buffered = true )
        raise NotImplemented
      end
      
      def expand_key( key )
        "#{NAMESPACE}/#{key}"
      end      
      
    end
  end
end  