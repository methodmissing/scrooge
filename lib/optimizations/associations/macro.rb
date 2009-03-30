module Scrooge
  module Optimizations 
    module Associations
      module Macro
        
        class << self
          
          # Inject into ActiveRecord
          #
          def install!
            unless scrooge_installed?
              ActiveRecord::Base.send( :extend,  SingletonMethods )
              ActiveRecord::Associations::AssociationProxy.send( :include, InstanceMethods )              
            end
          end
      
          protected
          
            def scrooge_installed?
              ActiveRecord::Associations::AssociationProxy.included_modules.include?( InstanceMethods )
            end
         
        end
        
      end
      
      module SingletonMethods
      
        @@preloadable_associations = {}
      
        def self.extended( base )
          eigen = class << base; self; end
          # not used at present
        end

        def preload_scrooge_associations(result_set, callsite_sig)
          if result_set.size > 1
            scrooge_preloading_exclude do
              if scrooge_callsite(callsite_sig).has_associations?
                callsite_associations = scrooge_callsite(callsite_sig).associations.to_preload
                unless callsite_associations.empty?
                  preload_associations(result_set, callsite_associations)
                end
              end
            end
          end
        end

        def scrooge_preloading_exclude
          unless Thread.current[:scrooge_preloading]
            Thread.current[:scrooge_preloading] = true
            yield
            Thread.current[:scrooge_preloading] = false
          end
        end
        
        # Let's not preload polymorphic associations or collections
        #      
        def preloadable_associations
          @@preloadable_associations[self.name] ||= 
            reflect_on_all_associations.reject{|a| a.options[:polymorphic] || a.macro == :has_many}.map(&:name)
        end

      end
      
      module InstanceMethods
        
        def self.included( base )
          base.alias_method_chain :load_target, :scrooge
        end

        # note AssociationCollection has its own version of load_target, but we don't
        # do collections at the moment anyway
        #
        def load_target_with_scrooge
          scrooge_seen_association!(@reflection)
          load_target_without_scrooge
        end

        private
        
          # Register an association with Scrooge
          #
          def scrooge_seen_association!( association )
            if @owner.scrooged? && !@loaded
              @owner.class.scrooge_callsite(callsite_signature).association!(association, @owner.id)
            end
          end
          
          def callsite_signature
            @owner.instance_variable_get(:@attributes).callsite_signature
          end
        
      end
      
    end
  end
end      