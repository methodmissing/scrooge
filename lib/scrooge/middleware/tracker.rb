module Scrooge
  module Middleware 
    class Tracker < Scrooge::Base
    
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