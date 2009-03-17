module Scrooge
  module Optimizations
    module ResultSets
      class UpdateableResultSet
        
        # Contains weak referernce to result set, and can update from DB
        #
        
        attr_accessor :updaters_attributes
        
        def initialize(result_set_array, klass)
          @result_set_object_id = result_set_array.object_id if result_set_array.is_a?(Array)
          @klass = klass  # expected class of items in the array
        end
        
        def reload_columns!(columns_to_fetch)
          reloaded_columns = reload_columns_for_ids(columns_to_fetch, result_set_ids)
          if !reloaded_columns.detect {|r| r[primary_key_name] == @updaters_attributes[primary_key_name]}
            raise ActiveRecord::MissingAttributeError, "scrooge cannot fetch missing attribute(s) #{columns_to_fetch.to_a.join(', ')} because record went away"
          else
            update_with(reloaded_columns)
          end
        end

        def reload_columns_for_ids(columns_to_fetch, result_ids_to_fetch)
          @klass.scrooge_reload(result_ids_to_fetch, columns_to_fetch + [primary_key_name])
        end

        def result_set_attributes
          if @result_set_object_id
            result_set = ObjectSpace._id2ref(@result_set_object_id)
            result_set.inject(default_attributes) do |memo, r|
              if r.is_a?(@klass)
                memo |= [r.instance_variable_get(:@attributes)]
              end
              memo
            end
          else
            default_attributes
          end
        rescue RangeError
          default_attributes
        end
        
        def default_attributes
          [@updaters_attributes]
        end
        
        def result_set_ids
          result_set_attributes.inject([]) do |memo, attributes|
            unless attributes.fully_fetched
              memo << attributes[primary_key_name]
            end
            memo
          end
        end
        
        def update_with(remaining_attributes)
          current_attributes = result_set_attributes
          remaining_attributes.each do |r_att|
            r_id = r_att[primary_key_name]
            old_attributes = current_attributes.detect {|a| a[primary_key_name] == r_id}
            if old_attributes
              old_attributes.update(r_att.merge(old_attributes))
            end
          end
        end
        
        def primary_key_name
          @klass.primary_key
        end      
      end
    end
  end
end