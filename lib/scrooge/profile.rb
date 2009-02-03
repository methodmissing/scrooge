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
        new( read_config( path, environment ) )
      end
      
      # Pairs profile setup with the host framework.
      #
      def setup!
        setup( framework.configuration_file, framework.environment )
      end
      
      # Yields an instance to a wrapper of the host framework.
      #
      def framework
        @@framework ||= Scrooge::Framework::Base.instantiate
      end
      
      private
      
        def read_config( path, environment ) #:nodoc:
          YAML.load( IO.read( path ) )[environment.to_s]
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
    
    def track!
      if track?
        log "Tracking"
        framework.install_tracking_middleware()
        shutdown_hook!
      end   
    end      
    
    # The active scope signature
    #
    def scope_to
      @scope
    end
        
    # Are we scoping ?
    #
    def scope?
      !track?
    end        
        
    # Scope the tracker environment to a given scope signature.
    #
    def scope_to_signature!( scope_signature )
      log "Scope to #{scope_signature}"
      @tracker_instance = framework.from_scope!( scope_signature )
    end
    
    # Scope the tracker environment to a given scope signature and install
    # scoping middleware.
    #
    def scope_to!
      if scope?
        scope_to_signature!( @scope )
        framework.install_scope_middleware( tracker )        
      end
    end
    alias :scope! :scope_to!
    
    # Should Scrooge inject itself ?
    #         
    def enabled?
      !@enabled.nil?
    end         
                
    private
    
      def configure! #:nodoc:
        @orm = @options['orm'] || :active_record
        @storage = @options['storage'] || :memory
        @scope = @options['scope'].to_s || nil
        @enabled = @options['enabled'] || false
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