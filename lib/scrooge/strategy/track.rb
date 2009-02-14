module Scrooge
  module Strategy
    class Track < Base
      
      stage :track, :for => Scrooge::Base.profile.warmup do
        
        log( "Tracking", true )
        framework.install_tracking_middleware()
        start_tracking!
        ::Kernel.at_exit do
          log( "Shutdown ...", true )
          framework.scope! if tracker.any?
        end
        
      end
      
    end
  end
end