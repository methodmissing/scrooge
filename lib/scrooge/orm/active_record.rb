module Scrooge
  module Orm
    class ActiveRecord < Base
      module ScroogeAttributes
        
        module SingletonMethods
                  
          def define_read_method(symbol, attr_name, column)
            if ::Scrooge::Base.profile.track?
              logger.info "[Scrooge] read method #{attr_name.inspect}"
              Thread.scrooge_resource << [self.base_class, attr_name]
            end
            super(symbol, attr_name, column)
          end
          
        end
        
        module InstanceMethods        
    
          def read_attribute(attr_name)
            if ::Scrooge::Base.profile.track?
              logger.info "[Scrooge] read attribute #{attr_name.inspect}"
              Thread.scrooge_resource << [self.class.base_class, attr_name]
            end
            super( attr_name )
          end
          
        end
      
      end
      
      class << self
        
        def install!
          profile.log "Installing ActiveRecord"
          ::ActiveRecord::Base.send( :extend, Scrooge::Orm::ActiveRecord::ScroogeAttributes::SingletonMethods )
          ::ActiveRecord::Base.send( :include, Scrooge::Orm::ActiveRecord::ScroogeAttributes::InstanceMethods )
        end
        
        def installed?
          begin
            ::ActiveRecord::Base.included_modules.include?( Scrooge::Orm::ActiveRecord::ScroogeAttributes )
          rescue => exception
            profile.log exception.to_s
          end
        end
        
      end
      
      def scope_to( resource )
        resource.models.each do |model|
          scope_resource_to_model( resource, model ) 
        end  
      end
      
      def scope_resource_to_model( resource, model )
        method_name = resource_scope_method( resource )
        model.instance_eval do
          (class << self; self end).send( :define_method, method_name ) do
            model.model.with_scope( to_scope( model ) ) do
              yield
            end
          end 
        end unless resource_scope_method?( resource )
      end      
      
      def name( model )
        model.base_class.to_s
      end
      
      def table_name( model )
        model.table_name
      end
          
      private
      
        def to_scope( model ) #:nodoc:
          { :find => { :select => model.to_sql } }
        end
      
    end  
  end  
end