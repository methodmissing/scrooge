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
      
        def self.extended( base )
          eigen = class << base; self; end
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
        
        private
        
          # Register an association with Scrooge
          #
          def scrooge_seen_association!( association )
            if scrooged?
              self.class.scrooge_callsite( @attributes.callsite_signature ).association!( association ) 
            end
          end        
        
      end
      
    end
  end
end      