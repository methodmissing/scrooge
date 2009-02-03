module Scrooge
  module Middleware 
    class Tracker < Scrooge::Base
    
      class << self
        
        # Around Filter compatible implementation for Rails as Dispatcher is 
        # the root Rack application and as such don't provide access to the Rails
        # Routing internals from other middleware.
        #
        def filter( controller, &block )
          Scrooge::Base.profile.tracker.track( Thread.scrooge_resource ) do
            begin
              Scrooge::Base.profile.framework.resource( {}, controller.request )
              Scrooge::Base.profile.log "Track for Resource #{Thread.scrooge_resource.inspect}"
              block.call
            ensure
              Thread.reset_scrooge_resource!
            end
          end
        end
        
      end
    
      def initialize(app, options = {})
        @app = app
      end
      
      # Assign a default Resource Tracker instance to Thread.current[:scrooge_resource] 
      # and supplement it with request specific details ( format, action && controller )
      # after yielding to the app.Flush Thread.current[:scrooge_resource] on completion.
      #
      def call(env)    
        Scrooge::Base.profile.tracker.track( Thread.scrooge_resource ) do
          begin
            result = @app.call(env)
            Scrooge::Base.profile.framework.resource( env )
            result
          ensure
            Thread.reset_scrooge_resource!
          end
        end
      end
      
    end
  end
end