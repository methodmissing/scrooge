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

        attr_accessor :callsite_signature, :scrooge_columns, :fully_fetched, :klass, :sql, :result_set_object_id

        def self.setup(record, scrooge_columns, klass, callsite_signature, result_set_object_id)
          hash = new.replace(record)
          hash.scrooge_columns = scrooge_columns.dup
          hash.fully_fetched = false
          hash.klass = klass
          hash.callsite_signature = callsite_signature
          hash.result_set_object_id = result_set_object_id
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
            remaining_attributes = fetch_records_with_remaining_columns( columns_to_fetch, result_set_ids )
            if !remaining_attributes.detect {|r| r[primary_key_name] == self[primary_key_name]}
              raise ActiveRecord::MissingAttributeError, "scrooge cannot fetch missing attribute(s) #{columns_to_fetch.to_a.join(', ')} because record went away"
            else
              update_result_set_with(remaining_attributes)
            end
          end

          def fetch_records_with_remaining_columns( columns_to_fetch, result_ids_to_fetch )
            @klass.scrooge_reload(result_ids_to_fetch, columns_to_fetch + [primary_key_name])
          end

          def result_set_attributes
            result_set = ObjectSpace._id2ref(@result_set_object_id)
            result_set.inject([self]) do |memo, r|
              if r.is_a?(@klass)
                memo |= [r.instance_variable_get(:@attributes)]
              end
              memo
            end
          rescue RangeError
            [self]
          end
          
          def result_set_ids
            result_set_attributes.inject([]) do |memo, attributes|
              unless attributes.fully_fetched
                memo << attributes[primary_key_name]
              end
              memo
            end
          end
          
          def update_result_set_with(remaining_attributes)
            current_attributes = result_set_attributes
            remaining_attributes.each do |r_att|
              r_id = r_att[primary_key_name]
              old_attributes = current_attributes.detect {|a| a[primary_key_name] == r_id}
              if old_attributes
                old_attributes.update(r_att.merge(old_attributes))
              end
            end
          end
          
          def interesting_for_scrooge?( attr_s )
            has_key?(attr_s) && !@scrooge_columns.include?(attr_s)
          end

          def augment_callsite!( attr_s )
            @klass.scrooge_seen_column!(callsite_signature, attr_s)
          end

          def primary_key_name
            @klass.primary_key
          end

          def dup_self
            @scrooge_columns = @scrooge_columns.dup
            self
          end
      end
    end
  end
end    