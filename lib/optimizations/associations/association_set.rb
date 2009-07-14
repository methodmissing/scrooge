module Scrooge
  module Optimizations 
    module Associations

      # Keeps track of how a result set is used to access associations
      # Each callsite where associations are accessed will contain one of 
      # these objects.
      # Each thread will collect data, and we check this data before each
      # fetch from the database, adding any associations that are needed
      # which are returned when to_preload is called.
      #
      # Note the the association set is only made by scrooge when an
      # association is accessed, so the first time through the code
      # data is not collected because we did not record the result set size.
      #
      class AssociationSet

        Mtx = Mutex.new

        def initialize
          @associations = SimpleSet.new
          @as_data_id = :"association_data_#{object_id}"
        end
        
        def register(association, record_id)
          assoc_data.register(association, record_id)
        end
        
        def register_result_set(result_set)
          assoc_data.register_result_set(result_set)
        end
        
        def reset
          Mtx.synchronize do
            @associations |= assoc_data.to_preload
          end
          assoc_data.reset
        end
        
        def to_preload
          @associations.to_a
        end
        
        private
        
        def assoc_data
          Thread.current[@as_data_id] ||= AssociationData.new
        end
      end
      
      class AssociationData
        def initialize
          reset
        end
        
        def reset
          @associations = {}
          @result_set_size = 0
        end
        
        def register(association, record_id)
          if @result_set_size > 1
            assoc = (@associations[association.name] ||= AssociationIdentity.new(association))
            assoc.register(record_id)
          end
        end
        
        def register_result_set(result_set)
          @result_set_size = result_set.size
        end
        
        def to_preload
          @associations.values.select { |association| preload_this_assoc?(association) }.map(&:name)
        end
        
        private

        # Calculate the benefit of preloading an association
        # There is no benefit if result set is just one record
        # Otherwise we look at how many of the result set items were used
        # to access the association - more than 25% and we preload
        #
        # TODO: more rules and analysis for different association types
        #        
        def preload_this_assoc?(association)
          if @result_set_size <= 1
            false
          else
            association.accessed_via.size > @result_set_size / 4
          end
        end
      end

      class AssociationIdentity
        attr_reader :name, :type, :accessed_via

        def initialize(association)
          @name = association.name
          @type = association.macro
          @accessed_via = []
        end

        def register(record_id)
          @accessed_via << record_id
        end
      end
    end
  end
end
