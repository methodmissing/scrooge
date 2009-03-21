module Scrooge
  module Optimizations
    module ResultSets
      class UpdateableResultSet
        
        # Contains a weak referernce to the result set, and can update from DB
        #
        
        attr_accessor :updaters_attributes
        
        def initialize(result_set_array, klass)
          if result_set_array
            @result_set_object_id = result_set_array.object_id
            @unique_id = result_set_array.unique_id ||= "#{Time.now.to_f}#{object_id}"  # avoid recycled object ids
          end
          @klass = klass  # expected class of items in the array
        end
        
        # Called by a ScroogedAttributes hash when it is asked for a column
        # that was not fetched from the DB
        #
        def reload_columns!(columns_to_fetch)
          reloaded_columns = hash_by_primary_key(reload_columns_for_ids(columns_to_fetch, result_set_ids))
          if !reloaded_columns.has_key?(@updaters_attributes[primary_key_name])
            raise ActiveRecord::MissingAttributeError, "scrooge cannot fetch missing attribute(s) #{columns_to_fetch.to_a.join(', ')} because record went away"
          else
            update_with(reloaded_columns)
          end
        end

        def reload_columns_for_ids(columns_to_fetch, result_ids_to_fetch)
          @klass.scrooge_reload(result_ids_to_fetch, columns_to_fetch + [primary_key_name])
        end

        def result_set_attributes
          rs = result_set
          return default_attributes unless rs
          rs.inject(default_attributes) do |memo, r|
            if r.is_a?(@klass)
              memo << r.instance_variable_get(:@attributes)
            end
            memo
          end.uniq
        end
        
        # The result set is weak referenced by its object_id
        # So we check that a unique id matches what we have remembered to make sure
        # that we got the right object (object ids are recycled by ruby)
        #
        def result_set
          return nil unless @result_set_object_id
          result_set = ObjectSpace._id2ref(@result_set_object_id)
          result_set.is_a?(ResultArray) && result_set.unique_id == @unique_id ? result_set : nil
        rescue RangeError
          nil
        end
        
        # When called from after_find and after_initialize, the object
        # being accessed (and causing the reload) is not in the result set yet.
        # We make sure that we add its attributes to result_set_attributes so it
        # gets reloaded too
        #
        def default_attributes
          [@updaters_attributes]
        end
        
        # Ids of the items to be reloaded
        #
        def result_set_ids
          result_set_attributes.inject([]) do |memo, attributes|
            unless attributes.fully_fetched
              memo << attributes[primary_key_name]
            end
            memo
          end
        end
        
        # Update the result set with attributes provided, as returned by
        # the sql server
        #
        def update_with(remaining_attributes)
          current_attributes = hash_by_primary_key(result_set_attributes)
          remaining_attributes.each do |r_id, r_att|
            old_attributes = current_attributes[r_id]
            if old_attributes
              old_attributes.update(r_att.merge(old_attributes)) # must call update, do not use reverse_update
            end
          end
        end
        
        # Make an efficient data structure to access items when the
        # primary key is known
        #
        def hash_by_primary_key(rows)
          rows.inject({}) {|memo, row| memo[row[primary_key_name]] = row; memo}
        end
        
        def primary_key_name
          @klass.primary_key
        end
        
      end
    end
  end
end