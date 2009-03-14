module Scrooge
  module Optimizations 
    module Columns
      module Macro
      
      end
      
      module SingletonMethods
        
      end
      
      module InstanceMethods
        
        # Is this instance being handled by scrooge?
        #
        def scrooged?
          @attributes.is_a?(Scrooge::Optimizations::Columns::AttributesProxy)
        end        
        
        # Delete should fully load all the attributes before the @attributes hash is frozen
        #
        alias_method :delete_without_scrooge, :delete
        def delete
          scrooge_fetch_remaining
          delete_without_scrooge
        end        
      
        # Destroy should fully load all the attributes before the @attributes hash is frozen
        #
        alias_method :destroy_without_scrooge, :destroy
        def destroy
          scrooge_fetch_remaining
          destroy_without_scrooge
        end      
        
        # Augment callsite info for new model class when using STI
        #
        def becomes(klass)
          returning klass.new do |became|
            became.instance_variable_set("@attributes", @attributes)
            became.instance_variable_set("@attributes_cache", @attributes_cache)
            became.instance_variable_set("@new_record", new_record?)
            if scrooged?
              self.class.scrooge_callsite_set(@attributes.callsite_signature).each do |attrib|
                became.class.augment_scrooge_callsite!(@attributes.callsite_signature, attrib)
              end
            end
          end
        end     

        # Marshal
        # force a full load if needed, and remove any possibility for missing attr flagging
        #
        def _dump(depth)
          scrooge_fetch_remaining
          scrooge_dump_flag_this
          str = Marshal.dump(self)
          scrooge_dump_unflag_this
          str
        end

        # Marshal.load
        # 
        def self._load(str)
          Marshal.load(str)
        end

        # Enables us to use Marshal.dump inside our _dump method without an infinite loop
        #
        alias_method :respond_to_without_scrooge, :respond_to?
        def respond_to?(symbol, include_private=false)
          if symbol == :_dump && scrooge_dump_flagged?
            false
          else
            respond_to_without_scrooge(symbol, include_private)
          end
        end

        private

          # Flag Marshal dump in progress
          #
          def scrooge_dump_flag_this
            Thread.current[:scrooge_dumping_objects] ||= []
            Thread.current[:scrooge_dumping_objects] << object_id
          end

          # Flag Marhsal dump not in progress
          #
          def scrooge_dump_unflag_this
            Thread.current[:scrooge_dumping_objects].delete(object_id)
          end

          # Flag scrooge as dumping ( excuse my French )
          #
          def scrooge_dump_flagged?
            Thread.current[:scrooge_dumping_objects] &&
            Thread.current[:scrooge_dumping_objects].include?(object_id)
          end

          def scrooge_fetch_remaining
            @attributes.fetch_remaining if scrooged?
          end
        
      end
      
    end
  end
end