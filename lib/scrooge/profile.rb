require 'yaml'

module Scrooge
  class Profile
    
    # A Profile for Scrooge that holds configuration, determines if we're tracking or
    # scoping and provides access to a Tracker, ORM, Storage and Framework instance. 
    
    class Signature      
    end
    
    class << self
      
      # Setup a new instance from the path to a YAML configuration file and a
      # given environment.
      #
      def setup( path, environment )
        new( YAML.load( IO.read( path ) )[environment.to_s] )
      end
      
      # Pairs profile setup with the host framework.
      #
      def setup!
        setup( File.join( framework.config, 'scrooge.yml' ), framework.environment )
      end
      
      # Yields an instance to a wrapper of the host framework.
      #
      def framework
        @@framework ||= Scrooge::Framework::Base.instantiate
      end
      
    end
               
    attr_reader :options           
               
    def initialize( options = {} )           
      self.options = options            
    end
    
    # options writer that attempts to reconfigure for any configuration changes.
    #
    def options=( options )
      @options = options
      configure!
    end
    
    # Should we do a warmup ?
    #
    def warmup?
      warmup_threshold != 0  
    end
    alias :warmed_up? :warmup?              
    
    # Should the tracking phase be buffered ?
    #     
    def buffer?
      buffer_threshold != 0   
    end     
    alias :buffered? :buffer?
    
    # Buffer threshold in seconds, if any.
    #    
    def buffer_threshold
      @buffer_threshold.to_i
    end
    
    # Warmup threshold, in seconds, if any.
    #
    def warmup_threshold
      @warmup_threshold.to_i
    end    
    
    # Delegates to the underlying ORM framework.
    #
    def orm
      @orm_instance ||= Scrooge::Orm::Base.instantiate( @orm )
    end

    # Delegates to the current storage backend. 
    #
    def storage
      @storage_instance ||= Scrooge::Storage::Base.instantiate( @storage )
    end
    
    # Delegates to the current framework.
    #
    def framework
      self.class.framework
    end
    
    # Log a message to the framework's logger.
    #
    def log( message )
      framework.log( message ) rescue ''
    end
    
    # Delegates to the Application Tracker.
    #
    def tracker
      @tracker_instance ||= Scrooge::Tracker::App.new
    end
      
    # Determine if this is a tracking or scope profile.
    #  
    def track_or_scope!
      track? ? track! : scope!
    end
    
    # Are we tracking ?
    #
    def track?
      @track ||= (@scope || '').match( /\d{10}/ ).nil?
    end
    
    def scope_to
      @scope
    end
  
    def track!
      if track?
        log "Tracking"
        framework.install_tracking_middleware()
        shutdown_hook!
      end   
    end  
    
    def scope_to!
      if scope?
        log "Scope to #{@scope}"
        @tracker_instance = framework.from_scope!( @scope )
        framework.install_scope_middleware( tracker )
      end
    end
    alias :scope! :scope_to!
    
    # Are we scoping ?
    #
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
        memoize_backends!
      end        
      
      # Force constant lookups as autoload is not threadsafe.
      #
      def memoize_backends! #:nodoc:
        framework()
        orm()
        storage()
        tracker()
      end
                  
      def shutdown_hook! #:nodoc:
        # Registers an at_exit hook to persist the current application scope.
        ::Kernel.at_exit do
          log "shutdown ..."
          framework.scope! if tracker.any? 
        end        
      end            
                  
  end
end