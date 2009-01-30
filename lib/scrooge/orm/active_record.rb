module Scrooge
  module Orm
    class ActiveRecord < Base
      module ScroogeAttributes
        
        def self.include( base )
          base.alias :original_read_attribute, :read_attribute
        end
        
        def read_attribute(attr_name)
          if ::Scrooge::Profile.orm.track?
            ::Scrooge::Profile.orm.resource << [self.class.base_class, attr_name]
          end
          original_read_attribute( attr_name )
        end
      end
      
      class << self
        
        def install!
          include Scrooge::Orm::ActiveRecord::ScroogeAttributes
        end
        
        def installed?
          include_modules.include?( Scrooge::Orm::ActiveRecord::ScroogeAttributes )
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
        model.base_name.to_s
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