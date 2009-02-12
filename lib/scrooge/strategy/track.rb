module Scrooge
  module Strategy
    class Track < Base
      
      stage :track, :for => 600 do
        Scrooge::Profile.track!
      end
      
    end
  end
end