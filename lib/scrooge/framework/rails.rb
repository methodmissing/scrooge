module Scrooge
  module Framework
    class Rails < Base
      
      signature do
        defined?(RAILS_ROOT)
      end
      
      signature do
        Object.const_defined?( "ActiveSupport" )
      end

      signature do
        Object.const_defined?( "ActionController" )
      end
      
      def environment
        ::Rails.env
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
      
      def resource( app )
        Scrooge::Tracker::Resource.new do |resource|
          resource.controller = app.request.path_parameters['controller']
          resource.action = app.request.path_parameters['action']
          resource.method = app.request.method
          resource.format = app.request.format
        end
      end      
      
      def read_cache( key )
        ::Rails.cache.read( key )
      end      
      
      def write_cache( key, value )
        ::Rails.cache.write( key, value )
      end
      
      def middleware( &block )
        ::ActionController::Dispatcher.middleware.instance_eval do
          block.call
        end
      end    
      
      def install_scope_middleware( tracker )
        tracker.resources.each do |resource|
          tracker.middleware.each do |resource_middleware|
            middleware do
              use resource_middleware
            end
          end
        end
      end
      
    end
  end
end