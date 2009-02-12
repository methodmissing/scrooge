module Scrooge
  module Strategy
    class Scope < Base
    
      stage :scope do
        Scrooge::Profile.scope!
      end    
      
    end
  end
end