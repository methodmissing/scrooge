module Scrooge
  module Core
    module Symbol
      
      # See Scrooge::Core::String
      
      def to_const
        to_s.to_const
      end
         
      def to_const!
        to_s.to_const!  
      end   
         
    end
  end
end

class Symbol
  include Scrooge::Core::Symbol
end