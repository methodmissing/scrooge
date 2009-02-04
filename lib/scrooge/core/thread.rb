module Scrooge
  module Core
    module Thread
      
      # Scrooge Resource tracker scoped to the current Thread for threadsafety in
      # multi-threaded environments.
      
      def scrooge_resource
        current[:scrooge_resource] ||= Scrooge::Tracker::Resource.new
      end
      
      def scrooge_resource=( resource )
        current[:scrooge_resource] = resource
      end
      
      def reset_scrooge_resource!
        current[:scrooge_resource] = nil
      end  
         
    end
  end
end

class Thread
  extend Scrooge::Core::Thread
end