require 'yaml'

module Scrooge
  class Profile
    
    class Signature      
    end
    
    class << self
      
      def setup( path, environment )
        new( YAML.load( IO.read( path ) )[environment.to_s] )
      end
      
      def framework
        @@framework ||= Scrooge::Framework::Base.instantiate
      end
      
    end
               
    attr_reader :options           
               
    def initialize( options = {} )           
      self.options = options            
    end
    
    def options=( options )
      @options = options
      configure!
    end
    
    def warmup?
      warmup_threshold != 0  
    end
    alias :warmed_up? :warmup?              
         
    def buffer?
      buffer_threshold != 0   
    end     
    alias :buffered? :buffer?
        
    def buffer_threshold
      @buffer_threshold.to_i
    end
    
    def warmup_threshold
      @warmup_threshold.to_i
    end    
    
    def orm
      @orm_instance ||= Scrooge::Orm::Base.instantiate( @orm )
    end

    def storage
      @storage_instance ||= Scrooge::Storage::Base.instantiate( @storage )
    end
    
    def framework
      self.class.framework
    end
    
    def tracker
      @tracker_instance ||= Scrooge::Tracker::App.new
    end
    
    def track?
      @scope.nil?
    end
    
    def scope_to
      @scope
    end
    
    def scope?
      !track?
    end
            
    private
    
      def configure! #:nodoc:
        @orm = @options['orm'] || :active_record
        @storage = @options['storage'] || :memory
        @buffer_threshold = @options['buffer_threshold'] || 0
        @warmup_threshold = @options['warmup_threshold'] || 0  
        @scope = @options['scope'] || nil
      end        
                  
  end
end