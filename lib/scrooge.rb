$:.unshift(File.dirname(__FILE__))

require 'yaml'
require 'fileutils'
require 'scrooge/core/string'
require 'scrooge/core/symbol'
require 'scrooge/core/thread'
require 'thread'

module Scrooge
  class Base
    
    GUARD = ::Mutex.new
    
    class << self
      
      # Active Profile reader
      #
      def profile
        @@profile ||= Scrooge::Profile.new
      end
      
      # Active Profile writer.
      #
      def profile=( profile )
        @@profile = profile
      end
      
      # Installs a YAML configuration template in the host framework's config
      # directory.
      #
      def setup!
        unless File.exist?( profile.framework.configuration_file )
          FileUtils.cp( configuration_template(), profile.framework.configuration_file )
        end  
      end
      
      private
      
        def configuration_template #:nodoc:
          File.join( File.dirname(__FILE__), '..', 'assets', 'config', 'scrooge.yml.template' )
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
require 'scrooge/strategy/base'