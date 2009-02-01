module Scrooge
  module Orm
    
    autoload :ActiveRecord, 'scrooge/orm/active_record'
        
    class Base < Scrooge::Base
      
      #
      #
      #
      
      class NotImplemented < StandardError
      end
      
      class << self
        
        def instantiate( orm_signature )
          orm_instance = "::Scrooge::Orm::#{orm_signature.to_const}".to_const!
          orm_instance.class.install! unless orm_instance.class.installed?
          orm_instance
        end
        
        def install!
          raise NotImplemented
        end
        
        def installed?
          raise NotImplemented
        end
        
      end

      def scope_to( resource )
        raise NotImplemented
      end
      
      def scope_resource_to_model( resource, model )
        raise NotImplemented
      end
      
      def name( model )
        raise NotImplemented
      end
      
      def table_name( model )
        raise NotImplemented
      end

      def resource_scope_method( resource )
        "scope_to_#{resource.signature}".to_sym
      end          
      
      def resource_scope_method?( resource, klass )
        klass.respond_to?( resource_scope_method( resource ) )
      end
      
      # Only track if the current profile is configured for tracking and a tracker
      # resource is active, iow. we're in the scope of a request.
      #
      def track?
        profile.track? && resource?
      end
      
      # Do we have access to Resource Tracker instance ?
      # 
      def resource?
        !resource().nil?
      end
      
      # Delegate to Thread.current
      #
      def resource
        Thread.current[:scrooge_resource]
      end
      
    end  
  end  
end