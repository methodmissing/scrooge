module Scrooge
  module Storage

    autoload :Lookup, 'scrooge/storage/lookup'    
    autoload :Buffer, 'scrooge/storage/buffer'
    autoload :FileSystem, 'scrooge/storage/file_system'
    autoload :Memory, 'scrooge/storage/memory'
    autoload :Cache, 'scrooge/storage/cache'
    
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
          "::Scrooge::Storage::#{storage_signature.to_const}".to_const!
        end
        
      end    
      
      # Enable a storage buffer by default.
      #
      def initialize
        extend Buffer
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
      
      # Commit a given tracker to the storage backend and register it's signature at
      # central lookup.
      #
      def <<( tracker )
        register_with_lookup!( tracker )
        write( tracker )
      end
      
      private
      
        def register_with_lookup!( tracker ) #:nodoc:
          lookup = unbuffered_read( Scrooge::Storage::Lookup::KEY ) || Scrooge::Storage::Lookup.new
          lookup << tracker
          unbuffered_write( lookup )
        end
      
    end
  end
end  