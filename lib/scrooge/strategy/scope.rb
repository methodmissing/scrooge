module Scrooge
  module Strategy
    class Scope < Base
    
      stage :scope do
        
        log( "Scope ...", true )
        scope = scope
        framework.install_scope_middleware( tracker )
       
      end    
      
    end
  end
end