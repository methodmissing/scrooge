module Scrooge
  module Middleware 
    class Tracker < Scrooge::Base
    
      def initialize(app, options = {})
        @app = app
      end
    
      def call(env)
        Scrooge::Profile.tracker.track( resource ) do
          @app.call(env)
        end
      end
      
      private
      
        def resource
          Scrooge::Profile.framework.resource( @app )
        end
    
    end
  end
end