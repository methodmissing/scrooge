module Scrooge
  module Framework
    class Rails < Base
      
      signature do
        !defined?(RAILS_ROOT).nil?
      end
      
      signature do
        Object.const_defined?( "ActiveSupport" )
      end

      signature do
        Object.const_defined?( "ActionController" )
      end
      
      def environment
        ::Rails.env.to_s
      end
      
      def root
        ::Rails.root
      end
      
      def tmp
        File.join( ::Rails.root, 'tmp' )
      end
      
      def config
        File.join( ::Rails.root, 'config' )
      end
      
      def logger
        ::Rails.logger
      end
      
      def resource( env )
        request = env['action_controller.rescue.request']
        Thread.scrooge_resource.controller = request.path_parameters['controller']
        Thread.scrooge_resource.action = request.path_parameters['action']
        Thread.scrooge_resource.method = request.method
        Thread.scrooge_resource.format = request.format.to_s        
      end      
      
      def read_cache( key )
        ::Rails.cache.read( key )
      end      
      
      def write_cache( key, value )
        ::Rails.cache.write( key, value )
      end
      
      def middleware
        # Before QueryCache, after MethodOverride
        # insert_at = ::Rails.configuration.middleware.size - 1
        ::Rails.configuration.middleware
      end    
      
      def install_tracking_middleware
        #insert_at = ::Rails.configuration.middleware.size - 3
        middleware.insert( 0, Scrooge::Middleware::Tracker )
        #middleware.use Scrooge::Middleware::Tracker 
        #middleware.insert(insert_at, Scrooge::Middleware::WhichResource )         
        #middleware.insert(insert_at + 2, Scrooge::Middleware::Tracker )         
      end
      
      def install_scope_middleware( tracker )
        tracker.resources.each do |resource|
          tracker.middleware.each do |resource_middleware|
            middleware.use( resource_middleware )
          end
        end
      end
      
      def initialized( &block )
        ::Rails.configuration.after_initialize( &block )
      end
      
    end
  end
end