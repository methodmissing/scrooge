module Scrooge
  module Strategy
    class TrackThenScope < Base
      
      stage :track, :for => Scrooge::Base.profile.warmup do

        log( "Installing tracking middleware ... ", true )
        framework.install_tracking_middleware()
        log( "Start tracking ... ", true )        
        start_tracking!
      
      end
      
      stage :synchronize, :for => 10 do
        
        log( "Uninstalling tracking middleware ... ", true )
        framework.uninstall_tracking_middleware
        log( "Stop tracking ... ", true )
        stop_tracking!
        log( "Synchronize results with other processes ...", true )
        tracker.synchronize!
      
      end
      
      stage :aggregate, :for => 10 do
        
        log( "Aggregate results from other processes ...", true )  
        tracker.aggregate!
      
      end      
      
      stage :scope do
        
        log( "Scope ...", true ) 
        framework.install_scope_middleware( tracker )
      
      end            
      
    end
  end
end