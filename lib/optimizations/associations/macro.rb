module Scrooge
  module Optimizations 
    module Associations
      module Macro
        
        class << self
          
          # Inject into ActiveRecord
          #
          def install!
            if scrooge_installable?
              ActiveRecord::Base.send( :extend,  SingletonMethods )
              ActiveRecord::Base.send( :include, InstanceMethods )              
            end  
          end
      
          private
          
            def scrooge_installable?
              !ActiveRecord::Base.included_modules.include?( InstanceMethods )
            end
         
        end
        
      end
      
      module SingletonMethods
      
        @@preloadable_associations = {}
        FindAssociatedRegex = /find_associated_records/
      
        def self.extended( base )
          eigen = class << base; self; end
          eigen.instance_eval do
            # Let :scrooge_callsite be a valid find option
            #
            remove_const(:VALID_FIND_OPTIONS)
            const_set( :VALID_FIND_OPTIONS, [ :conditions, :include, :joins, :limit, :offset, :order, :select, :readonly, :group, :having, :from, :lock, :scrooge_callsite ] )
          end
          eigen.alias_method_chain :find, :scrooge
          eigen.alias_method_chain :find_every, :scrooge
        end
      
        # Let .find setup callsite information and preloading.
        #
        def find_with_scrooge(*args)
          options = args.extract_options!
          validate_find_options(options)
          set_readonly_option!(options)

          if (_caller = caller).grep( FindAssociatedRegex ).empty?
            cs_signature = callsite_signature( _caller, options.except(:conditions, :limit, :offset) )
            options[:scrooge_callsite], options[:include] = cs_signature, scrooge_callsite(cs_signature).preload( options[:include] )
          end

          case args.first
            when :first then find_initial(options)
            when :last  then find_last(options)
            when :all   then find_every(options)
            else             find_from_ids(args, options)
          end
        end
      
        # Override find_ever to pass along the callsite signature
        #
        def find_every_with_scrooge(options)
          include_associations = merge_includes(scope(:find, :include), options[:include])

          if include_associations.any? && references_eager_loaded_tables?(options)
            records = find_with_associations(options)
          else
            records = find_by_sql(construct_finder_sql(options), options[:scrooge_callsite])
            if include_associations.any?
              preload_associations(records, include_associations)
            end
          end

          records.each { |record| record.readonly! } if options[:readonly]

          records
        end      
        
        # Let's not preload polymorphic associations or collections
        #      
        def preloadable_associations
          @@preloadable_associations[self.name] ||= reflect_on_all_associations.reject{|a| a.options[:polymorphic] || a.macro == :has_many }.map{|a| a.name }
        end              
              
      end
      
      module InstanceMethods
                
        # Association getter with Scrooge support
        #
        def association_instance_get(name)
          association = instance_variable_get("@#{name}")
          if association.respond_to?(:loaded?)
            scrooge_seen_association!( name )
            association
          end
        end

        # Association setter with Scrooge support
        #
        def association_instance_set(name, association)
          scrooge_seen_association!( name )
          instance_variable_set("@#{name}", association)
        end
        
        # Register an association with Scrooge
        #
        def scrooge_seen_association!( association )
          if scrooged? && !scrooge_seen_association?( association )
            @attributes.scrooge_associations << association
            self.class.scrooge_callsite( @attributes.callsite_signature ).association!( association ) 
          end
        end
        
        private
        
          def scrooge_seen_association?( association )
            @attributes.scrooge_associations.include?( association )
          end
        
      end
      
    end
  end
end      