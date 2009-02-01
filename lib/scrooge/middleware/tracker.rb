module Scrooge
  module Middleware 
    class Tracker < Scrooge::Base
    
      def initialize(app, options = {})
        @app = app
      end

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