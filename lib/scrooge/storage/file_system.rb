module Scrooge
  module Storage
    class FileSystem < Base

      def initialize
        extend Buffer
      end  
  
      def read( tracker )
        GUARD.synchronize do
          begin
            File.open( tracker_file( tracker ), 'rb') {|t| Marshal.load(t) }
          rescue => exception
            profile.framework.logger.error "Scrooge: Could not read storage entry #{tracker.key} (#{exception.to_s})"
          end
        end  
      end      
      
      def write( tracker, buffered = true )
        GUARD.synchronize do
          begin
            ensure_tracker_path( tracker ) do
              File.open( tracker_file( tracker ), 'w') {|t| Marshal.dump( tracker, t ) }
            end
          rescue => exception
            profile.framework.logger.error "Scrooge: Could not write storage entry #{tracker.key} (#{exception.to_s})"
          end
        end  
      end  
      
      def tracker_file( tracker )
        File.join( tracker_path( tracker ), 'scrooge' )
      end
    
      def tracker_path( tracker )
        File.join( profile.framework.tmp, tracker.signature )
      end      
      
      private
        
        def ensure_tracker_path( tracker ) #:nodoc:
          FileUtils.makedirs( tracker_path( tracker ) ) unless File.exist?( tracker_path( tracker ) )
          yield if block_given?
        end
      
    end
  end
end