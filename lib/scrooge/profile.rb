require 'yaml'

module Scrooge
  class Profile
    
    # A Profile for Scrooge that holds configuration, determines if we're tracking or
    # scoping and provides access to a Tracker, ORM, Storage and Framework instance. 
    
    class << self
      
      # Setup a new instance from the path to a YAML configuration file and a
      # given environment.
      #
      def setup( path, environment )
        begin
          new( read_config( path, environment ) )
        rescue ::Errno::ENOENT
          puts "Scrooge Configuration file not available."
        end
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
    
    # Delegates to the Application Tracker.
    #
    def tracker
      @tracker_instance ||= Scrooge::Tracker::App.new
    end

    # Yields a strategt instance.
    #           
    def strategy
      @strategy_instance ||= "scrooge/strategy/#{@strategy.to_s}".to_const!  
    end
    
    # Delegates to the current framework.
    #
    def framework
      self.class.framework
    end
    
    # Log a message to the framework's logger.
    #
    def log( message, flush = false )
      framework.log( message, flush ) rescue ''
    end
        
    # Are we tracking ?
    #
    def track?
      if enabled?
        @track ||= (@scope || '').match( /\d{10}/ ).nil?
      else
        false
      end  
    end   
    
    # The active scope signature
    #
    def scope
      @scope
    end     
    
    # Assign the current scope from a given signature or tracker
    #    
    def scope=( signature_or_tracker )
      if signature_or_tracker.kind_of?( Scrooge::Tracker::Base )
        scope_to_tracker!( signature_or_tracker )
      else
        scope_to_signature!( signature_or_tracker  )
      end
    end    
            
    # Should Scrooge inject itself ?
    #         
    def enabled?
      @enabled
    end         
    
    # Should we raise on missing attributes ?
    #
    def raise_on_missing_attribute?
      @on_missing_attribute == :raise
    end        
    
    # Expose the warmup phase during which tracking occur.
    #  
    def warmup            
      @warmup
    end            
                
    private
    
      def configure! #:nodoc:
        @orm = configure_with( @options['orm'], [:active_record], :active_record )
        @storage = configure_with( @options['storage'], [:memory], :memory )
        @strategy = configure_with( @options['strategy'], [:track, :scope, :track_then_scope], :track )
        @scope = configure_with( @options['scope'].to_s, framework_scopes, ENV['scope'] )
        @warmup = configure_with( @options['warmup'].to_s, 0..14400, 600 )        
        @enabled = configure_with( @options['enabled'], [true, false], false )
        @on_missing_attribute = configure_with( @options['on_missing_attribute'], [:reload, :raise], :reload )
        reset_backends!
        memoize_backends!
      end        
      
      def framework_scopes #:nodoc:
        framework.scopes rescue []
      end
    
      def configure_with( given, valid, default ) #:nodoc:
        if given
          valid.include?( given ) ? given : default
        else
          default
        end    
      end
      
      def reset_backends! #:nodoc:
        @orm_instance = nil
        @tracker_instance = nil
        @storage_instance = nil
        @strategy_instance = nil
      end
      
      # Force constant lookups as autoload is not threadsafe.
      #
      def memoize_backends! #:nodoc:
        framework() rescue nil
        orm()
        storage()
        tracker()
        strategy()
      end         
        
      def scope_to_signature!( scope_signature ) #:nodoc:
        log "Scope to signature #{scope_signature} ..."
        @tracker_instance = framework.from_scope!( scope_signature )
      end

      def scope_to_tracker!( tracker ) #:nodoc:
        log "Scope to tracker #{tracker.inspect} ..."
        @tracker_instance = tracker
      end
                        
  end
end