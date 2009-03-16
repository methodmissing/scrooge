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
      end
      
      module InstanceMethods

        def association_instance_get(name)
          association = instance_variable_get("@#{name}")
          if association.respond_to?(:loaded?)
            scrooge_seen_association!( name )
            association
          end
        end

        def association_instance_set(name, association)
          scrooge_seen_association!( name )
          instance_variable_set("@#{name}", association)
        end
        
        def scrooge_seen_association!( association )
          if scrooged?
            self.class.scrooge_callsite( @attributes.callsite_signature ).association!( association ) 
          end
        end
        
      end
      
    end
  end
end      