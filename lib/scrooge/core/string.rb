module Scrooge
  module Core
    module String
      
      # Framework agnostic String <=> Constant helpers.
      # Perhaps not the cleanest abstraction, but also not good practice to piggy
      # back on or use a naming convention that may clash with and uproot the API
      # any given framework ships with.
      
      def to_const
        self.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      end
      
      def to_const!( instantiate = true )
        begin
          const = Object.module_eval(to_const, __FILE__, __LINE__)
          instantiate ? const.new : const
        rescue => exception 
          exception.to_s.match( /uninitialized constant/ ) ? self : raise
        end
      end
         
    end
  end
end

class String
  include Scrooge::Core::String
end