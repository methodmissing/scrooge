module Scrooge
  module Strategy
    class Track < Base
      
      stage :track, :for => 600 do
        
        log( "Tracking", true )
        framework.install_tracking_middleware()
        ::Kernel.at_exit do
          log( "Shutdown ...", true )
          framework.scope! if tracker.any?
        end
        
      end
      
    end
  end
end