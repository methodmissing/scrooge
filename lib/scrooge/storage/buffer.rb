module Scrooge
  module Storage
    module Buffer
      
      attr_accessor :storage_buffer,
                    :buffered_at
      
      def storage_buffer 
        @storage_buffer ||= {}
      end
      
      def buffered_at
        @buffered_at ||= Time.now.to_i
      end
      
      def read( tracker )
        with_read_buffer( tracker ) do
          super( tracker )
        end
      end      
            
      def write( tracker, buffered = true )
        if buffered
          with_write_buffer( tracker ) do
            super( tracker, buffered )
          end
        else
          super( tracker, buffered )
        end       
      end      
      
      def buffer?
        profile.buffer?  
      end 
      
      def flush_buffer?
        if buffer?
          ( buffered_at + profile.buffer_threshold ) < Time.now.to_i
        else
          false
        end  
      end      

      def buffer( tracker )
        storage_buffer[tracker.signature] = tracker
      end
      
      def flush!
        while( !storage_buffer.empty? ) do
          write( storage_buffer.shift.last, false )
        end
        buffered_at = Time.now.to_i
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