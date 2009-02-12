module Scrooge
  module Strategy
    class TrackThenScope < Base
      
      stage :track, :for => 600 do
        #
      end
      
      stage :aggregate, :for => 60 do
        #
      end      
      
      stage :scope do
        #
      end            
      
    end
  end
end