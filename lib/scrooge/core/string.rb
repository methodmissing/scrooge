module Scrooge
  module Core
    module String
      
      # Thx ActiveSupport
      def to_const
        self.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      end
         
    end
  end
end

class String
  include Scrooge::Core::String
end