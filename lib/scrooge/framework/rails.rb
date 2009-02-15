module Scrooge
  module Framework
    class Rails < Base
      
      # Look for RAILS_ROOT and Rails.
      
      signature do
        defined?(RAILS_ROOT)
      end
      
      signature do
        Object.const_defined?( "Rails" )
      end
      
      def environment
        ::RAILS_ENV
      end
      
      def root
        ::Rails.root
      end
      
      def tmp
        @tmp ||= File.join( ::Rails.root, 'tmp' )
      end
      
      def config
        @config ||= File.join( ::Rails.root, 'config' )
      end
      
      def logger
        ::Rails.logger
      end
      
      def resource( env, request = nil )
        GUARD.synchronize do
          # TODO: Wonky practice to piggy back on this current Edge / 2.3 hack
          request = request || env['action_controller.rescue.request']
          supplement_current_resource!( request )
          Thread.scrooge_resource = Scrooge::Base.profile.tracker.resource_for( Thread.scrooge_resource )      
        end
      end      
      
      def read_cache( key )
        ::Rails.cache.read( key )
      end      
      
      def write_cache( key, value )
        ::Rails.cache.write( key, value )
      end
      
      def middleware
        ::Rails.configuration.middleware
      end    
      
      # Push the Tracking middleware into the first slot. 
      #      
      def install_tracking_middleware
        GUARD.synchronize do
          with_or_without_prepatation( :scrooge_install_tracking_middleware ) do
            ApplicationController.prepend_around_filter Scrooge::Middleware::Tracker
          end
        end
      end
      
      # Remove all tracking filters
      #
      def uninstall_tracking_middleware
        GUARD.synchronize do
          # Handle dev. mode
          ActionController::Dispatcher.prepare_dispatch_callback_chain.delete( :scrooge_install_tracking_middleware )
          ApplicationController.skip_filter Scrooge::Middleware::Tracker
        end
      end
      
      # Install per Resource scoping middleware.
      #
      def install_scope_middleware( tracker )
        GUARD.synchronize do
          with_or_without_prepatation( :scrooge_install_scope_middleware ) do
            tracker.resources.each do |resource|
              install_scope_middleware_for_resource!( resource )
            end
         end  
        end  
      end
      
      def initialized( &block )
        begin
          ::Rails.configuration.after_initialize( &block )
        rescue NameError
          # No config initialized - plugin installation etc.
        end  
      end
      
      def controller( resource )
        "#{resource.controller}_controller".classify.constantize
      end
      
      private 
      
        def with_or_without_prepatation( callback_signature, &block )
          if development?
            ActionController::Dispatcher.to_prepare( callback_signature ) do
              block.call
            end
          else
            block.call
          end      
        end
      
        def development? #:nodoc:
          environment == 'development'
        end
      
        def install_scope_middleware_for_resource!( resource ) #:nodoc:
          resource.middleware.each do |resource_middleware|
            controller( resource ).prepend_around_filter resource_middleware, :only => resource.action
          end
        end
      
        def supplement_current_resource!( request ) #:nodoc:
          Thread.scrooge_resource.controller = request.path_parameters['controller']
          Thread.scrooge_resource.action = request.path_parameters['action']
          Thread.scrooge_resource.method = request.method
          Thread.scrooge_resource.format = request.format.to_s  
        end
      
    end
  end
end