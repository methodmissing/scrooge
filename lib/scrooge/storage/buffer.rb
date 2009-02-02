module Scrooge
  module Storage
    module Buffer
      
      GUARD = Mutex.new
      
      attr_accessor :storage_buffer,
                    :buffer_flushed_at
      
      # Initialize with an empty storage buffer.
      #
      def storage_buffer 
        @storage_buffer ||= {}
      end
      
      # Calculate when the buffer was last flushed.
      #
      def buffer_flushed_at
        GUARD.synchronize do
          @buffer_flushed_at ||= Time.now.to_i
        end
      end
      
      # Buffered read.
      #
      def read( tracker )
        GUARD.synchronize do
          with_read_buffer( tracker ) do
            super( tracker )
          end
        end  
      end      
      
      # Buffered write.
      #      
      def write( tracker, buffered = true )
        GUARD.synchronize do
          if buffered
            with_write_buffer( tracker ) do
              super( tracker, buffered )
            end
          else
            super( tracker, buffered )
          end
        end         
      end      
      
      # Determine if we should buffer at all. 
      #
      def buffer?
        profile.buffer?  
      end 
      
      # Determine if the buffer should be flushed.
      #
      def flush_buffer?
        if buffer?
          ( buffer_flushed_at + profile.buffer_threshold ) < Time.now.to_i
        else
          false
        end
      end      

      # Buffers a given tracker instance.
      #
      def buffer( tracker )
        storage_buffer[tracker.signature] = tracker
      end
      
      # Flush the current buffer.
      def flush!
        GUARD.synchronize do
          while( !storage_buffer.empty? ) do
            write( storage_buffer.shift.last, false )
          end
          buffer_flushed_at = Time.now.to_i
        end
      end
      
      private
      
        def with_read_buffer( tracker ) #:nodoc:
          if flush_buffer?  
            flush!
            storage_buffer[tracker.signature]            
          else
            yield
          end    
        end
      
        def with_write_buffer( tracker ) #:nodoc:
          if flush_buffer?
            flush!              
            buffer( tracker )
          else
            yield
          end    
        end
      
    end
  end
end