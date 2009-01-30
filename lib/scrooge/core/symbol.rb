module Scrooge
  module Core
    module Symbol
      
      def to_const
        to_s.to_const
      end
         
    end
  end
end

class Symbol
  include Scrooge::Core::Symbol
end