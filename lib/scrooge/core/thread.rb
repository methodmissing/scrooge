module Scrooge
  module Core
    module Thread
      
      def scrooge_resource
        current[:scrooge_resource] ||= Scrooge::Tracker::Resource.new
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