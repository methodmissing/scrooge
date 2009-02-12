module Scrooge
  module Strategy
    class TrackThenScope < Base
      
      stage :track, :for => 600 do
        Scrooge::Profile.track!
        uninstall_tracking_middleware
      end
      
      stage :aggregate, :for => 10 do
        Scrooge::Profile.aggregate!
      end      
      
      stage :scope do
        Scrooge::Profile.scope!
      end            
      
    end
  end
end