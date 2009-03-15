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
      end

      class ScroogedAttributes < Hash
        
        # Hash container for attributes with scrooge monitoring of attribute access
        #        

        attr_accessor :callsite_signature, :scrooge_columns, :fully_fetched, :klass

        def self.setup(record, scrooge_columns, klass, callsite_signature)
          hash = new.replace(record)
          hash.scrooge_columns = scrooge_columns.dup
          hash.fully_fetched = false
          hash.klass = klass
          hash.callsite_signature = callsite_signature
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
          keys.include?(attr_name.to_s)
        end

        alias_method :include?, :has_key?
        alias_method :key?, :has_key?
        alias_method :member?, :has_key?

        # Lazily augment and load missing attributes
        #
        def [](attr_name)
          attr_s = attr_name.to_s
          if interesting_for_scrooge?( attr_s )
            augment_callsite!( attr_s )
            fetch_remaining
            @scrooge_columns << attr_s
          end
          super
        end

        def fetch(*args, &block)
          self[args[0]]
          super
        end

        def []=(attr_name, value)
          @scrooge_columns << attr_name.to_s
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
            columns_to_fetch = @klass.column_names - @scrooge_columns.to_a
            unless columns_to_fetch.empty?
              fetch_remaining!( columns_to_fetch )
            end
            @fully_fetched = true
          end
        end

        protected

          def fetch_remaining!( columns_to_fetch )
            begin
              remaining_attributes = fetch_record_with_remaining_columns( columns_to_fetch )
            rescue ActiveRecord::RecordNotFound
              raise ActiveRecord::MissingAttributeError, "scrooge cannot fetch missing attribute(s) #{columns_to_fetch.to_a.join(', ')} because record went away"
            end
            replace(remaining_attributes.merge(self))
          end

          def fetch_record_with_remaining_columns( columns_to_fetch )
            @klass.scrooge_reload(self[@klass.primary_key], columns_to_fetch)
          end

          def interesting_for_scrooge?( attr_s )
            has_key?(attr_s) && !@scrooge_columns.include?(attr_s)
          end

          def augment_callsite!( attr_s )
            @klass.scrooge_seen_column!(callsite_signature, attr_s)
          end

          def dup_self
            @scrooge_columns = @scrooge_columns.dup
            self
          end
      end
    end
  end
end    