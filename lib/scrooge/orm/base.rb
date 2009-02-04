module Scrooge
  module Orm
    
    autoload :ActiveRecord, 'scrooge/orm/active_record'
        
    class Base < Scrooge::Base
      
      # ORM agnostic base class.
      
      class NotImplemented < StandardError
      end
      
      class << self
        
        # Instantiate and optionally install from a given ORM signature.
        #
        def instantiate( orm_signature )
          orm_instance = "scrooge/orm/#{orm_signature.to_s}".to_const!
          orm_instance.class.install! unless orm_instance.class.installed?
          orm_instance
        end
        
        # Subclasses is required to implemented an installation hook.
        #
        def install!
          raise NotImplemented
        end
        
        # Subclasses should be able to determine if it's already been injected into 
        # the underlying ORM package.
        #
        def installed?
          raise NotImplemented
        end
        
      end

      # Generate scope helpers for a Resource and it's related Model trackers.
      #
      def scope_to( resource )
        raise NotImplemented
      end
      
      # Generate scope helpers for a given Resource and Model tracker.
      #
      def scope_resource_to_model( resource, model )
        raise NotImplemented
      end
   
      # Returns a lookup key from a given String or class 
      #      
      def name( model )
        raise NotImplemented
      end

      # Returns a table name from a given String or class 
      #      
      def table_name( model )
        raise NotImplemented
      end

      # Returns a primary key from a given String or class
      #
      def primary_key( model )
        raise NotImplemented
      end

      # Generates a sanitized method name for a given resource.
      #
      def resource_scope_method( resource )
        "scope_to_#{resource.signature}".to_sym
      end          
      
      # Determine if a scope method has already been generated for a given
      # Resource and klass.
      #
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