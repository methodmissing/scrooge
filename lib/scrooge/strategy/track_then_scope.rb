module Scrooge
  module Strategy
    class TrackThenScope < Base
      
      stage :track, :for => 600 do
        
        log( "Tracking", true )
        framework.install_tracking_middleware()
        framework.uninstall_tracking_middleware
      
      end
      
      stage :synchronize, :for => 10 do
        
        log( "Synchronize results with other processes ...", true )
        tracker.synchronize!
      
      end
      
      stage :aggregate, :for => 10 do
        
        log( "Aggregate results from other processes ...", true )  
        tracker.aggregrate!
      
      end      
      
      stage :scope do
        
        log( "Scope ...", true ) 
        framework.install_scope_middleware( tracker )
      
      end            
      
    end
  end
end