$:.unshift(File.dirname(__FILE__))

require 'yaml'
require 'scrooge/core/string'
require 'scrooge/core/symbol'
require 'scrooge/core/thread'

module Scrooge
  class Base
    
    class << self
      
      def profile
        @@profile ||= Scrooge::Profile.new
      end
      
      def profile=( profile )
        @@profile = profile
      end
      
    end
    
    def profile
      self.class.profile
    end
    
  end 

  module Middleware
    autoload :Tracker, 'scrooge/middleware/tracker'
  end 

end

require 'scrooge/profile'
require 'scrooge/storage/base'
require 'scrooge/orm/base'
require 'scrooge/framework/base'
require 'scrooge/tracker/base'