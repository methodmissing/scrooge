module Scrooge
  module Optimizations
    module Columns
      class UnscroogedAttributes < Hash

        # Hash container for attributes when scrooge is not used
        #        

        def self.setup(record)
          new.replace(record)
        end

        # Must call to_hash - other hash may be ScroogedAttributes and
        # must be fully fetched if so
        #
        def update(hash)
          super(hash.to_hash)
        end

        alias_method :merge!, :update
        
        # Don't try to reload one of these
        #
        def fully_fetched
          true
        end
      end

      class ScroogedAttributes < Hash
        
        # Hash container for attributes with scrooge monitoring of attribute access
        #        

        attr_accessor :fully_fetched, :klass, :updateable_result_set

        def self.setup(record, klass, updateable_result_set)
          hash = new.replace(record)
          hash.fully_fetched = false
          hash.klass = klass
          hash.updateable_result_set = updateable_result_set
          hash
        end

        # Delegate Hash keys to all defined columns
        #
        def keys
          @klass.column_names
        end

        # Let #has_key? consider defined columns
        #
        def has_key?(attr_name)
          @klass.columns_hash.has_key?(attr_name)
        end

        alias_method :include?, :has_key?
        alias_method :key?, :has_key?
        alias_method :member?, :has_key?

        # Lazily augment and load missing attributes
        #
        def [](attr_name)
          if interesting_for_scrooge?( attr_name )
            augment_callsite!( attr_name )
            fetch_remaining
            add_to_scrooge_columns(attr_name)
          end
          super
        end

        def fetch(*args, &block)
          self[args[0]]
          super
        end

        def []=(attr_name, value)
          add_to_scrooge_columns(attr_name)
          super
        end
        
        alias_method :store, :[]=

        def dup
          super.dup_self
        end

        def to_hash
          fetch_remaining
          super
        end

        def to_a
          fetch_remaining
          super
        end

        def delete(attr_name)
          self[attr_name]
          super
        end

        def update(hash)
          @fully_fetched = true
          super(hash.to_hash)
        end
        
        alias_method :merge!, :update

        def fetch_remaining
          unless @fully_fetched
            columns_to_fetch = @klass.column_names - scrooge_columns.to_a
            unless columns_to_fetch.empty?
              fetch_remaining!( columns_to_fetch )
            end
            @fully_fetched = true
          end
        end
        
        def callsite_signature
          @updateable_result_set.callsite_signature
        end
        
        def scrooge_columns
          @scrooge_columns || @updateable_result_set.scrooge_columns
        end
        
        protected

          def fetch_remaining!( columns_to_fetch )
            @updateable_result_set.updaters_attributes = self  # for after_initialize & after_find
            @updateable_result_set.reload_columns!(columns_to_fetch)
          end
          
          def interesting_for_scrooge?( attr_name )
            @klass.columns_hash.has_key?(attr_name) && !scrooge_columns.include?(attr_name)
          end

          def augment_callsite!( attr_name )
            @klass.scrooge_seen_column!(callsite_signature, attr_name)
          end

          def add_to_scrooge_columns(attr_name)
            unless frozen?
              @scrooge_columns ||= @updateable_result_set.scrooge_columns.dup
              @scrooge_columns << attr_name
            end
          end

          def primary_key_name
            @klass.primary_key
          end

          def dup_self
            @scrooge_columns = @scrooge_columns.dup if @scrooge_columns
            self
          end
      end
    end
  end
end    
