require 'yaml'

module Scrooge
  class Profile
    
    class Signature      
    end
    
    class << self
      
      def setup( path, environment )
        new( YAML.load( IO.read( path ) )[environment.to_s] )
      end
      
      def setup!
        setup( File.join( framework.config, 'scrooge.yml' ), framework.environment )
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
    
    def log( message )
      framework.log( message ) rescue ''
    end
    
    def tracker
      @tracker_instance ||= Scrooge::Tracker::App.new
    end
    
    def track!
      require 'pp'
      if track?
        log "Tracking"
        orm() # force setup
        framework.install_tracking_middleware()
        ::Kernel.at_exit do
          framework.scope!
        end
      end   
    end
    
    def track?
      @track ||= (@scope || '').match( /\d{10}/ ).nil?
    end
    
    def scope_to
      @scope
    end
    
    def scope_to!
      @tracker_instance = framework.from_scope!( @scope )
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
        @scope = @options['scope'].to_s || nil
      end        
                  
  end
end