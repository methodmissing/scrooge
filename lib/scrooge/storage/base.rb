module Scrooge
  module Storage
   
    autoload :Memory, 'scrooge/storage/memory'
    
    class Base < Scrooge::Base
      class NotImplemented < StandardError
      end 
      
      # A Single Mutex for all Storage subclasses as their's only one storage instance.
      #
      GUARD = Mutex.new
      
      NAMESPACE = 'scrooge_storage'.freeze 
          
      class << self
        
        # Yields a storage instance from a given signature.
        #
        def instantiate( storage_signature )
          "scrooge/storage/#{storage_signature.to_s}".to_const!
        end
        
      end    

      # Retrieve a given tracker from storage.
      #                 
      def read( tracker )
        raise NotImplemented
      end      
            
      # Persist a given tracker to storage.
      #      
      def write( tracker, buffered = true )
        raise NotImplemented
      end
      
      # Namespace lookup keys. 
      #
      def expand_key( key )
        "#{NAMESPACE}/#{key}"
      end      
      
    end
  end
end  