module Scrooge
  module Framework
    
    # Scrooge is framework agnostic and attempts to abstract the following :
    #
    # * current environment
    # * app root dir
    # * app tmp dir
    # * app config dir 
    # * logging    
    # * resource endpoints 
    # * caching
    # * injecting Rack MiddleWare 
    #
    # Framework Signatures 
    #
    # Scrooge will attempt to determine the current active framework it's deployed with
    # through various framework specific hooks.
    #
    # module Scrooge
    #    module Framework
    #      module YetAnother < Base
    #        ...
    #        signature do
    #          Object.const_defined?( "UnlikeAnyOther" )
    #        end
    #        ...
    #      end
    #    end
    #  end 
    
    autoload :Rails, 'scrooge/framework/rails'
    
    class Base < Scrooge::Base
      class NotImplemented < StandardError
      end
      
      class NoSupportedFrameworks < StandardError
      end
      
      class InvalidScopeSignature < StandardError
      end        
   
      class << self

        # Per framework signature lookup.
        #        
        @@signatures = {}
        @@signatures[self.name] = Hash.new( [] )
        
        # Support none by default.
        #
        @@frameworks = []        
                
        # Registers a framework signature.
        #        
        def signature( &block )
          @@signatures[self.name] = signatures << block
        end  
        
        # 
        def signatures
          @@signatures[self.name] || []
        end
        
        # All supported frameworks.
        #
        def frameworks
          @@frameworks
        end
        
        # Infer the framework Scrooge attaches to in a first yield manner.
        # A match of all defined signatures is required.
        #
        def which_framework?
          iterate_frameworks() || raise( NoSupportedFrameworks )
        end
        
        # Yield an instance of the current framework.
        #
        def instantiate
          which_framework?().new
        end
        
        private
        
          def inherited( subclass ) #:nodoc:
            @@frameworks << subclass
          end
        
          def iterate_frameworks #:nodoc:
            frameworks.detect do |framework|
              framework.signatures.all?{|sig| sig.call }
            end
          end  
                        
      end
      
      def environment
        raise NotImplemented
      end
      
      def root
        raise NotImplemented  
      end
      
      def tmp
        raise NotImplemented
      end      
      
      def config
        raise NotImplemented
      end
      
      def logger
        raise NotImplemented
      end
      
      def resource( env )
        raise NotImplemented
      end
      
      def write_cache( key, value )
        raise NotImplemented
      end
      
      def read_cache( key )
        raise NotImplemented
      end 
      
      def middleware
        raise NotImplemented
      end
      
      def install_scope_middleware( tracker )
        raise NotImplemented
      end
      
      def install_tracking_middleware
        raise NotImplemented
      end
      
      def initialized( &block )
        raise NotImplemented
      end
      
      # Retrieve all previously persisted scopes tracked with Scrooge. 
      #
      def scopes
        ensure_scopes_path do
          Dir.entries( scopes_path ).grep(/\d{10}/)
        end
      end
      
      # Return the scopes storage path for the current framework.
      #
      def scopes_path
        @profiles_path ||= File.join( config, 'scrooge', 'scopes' )
      end

      # Return the scopes storage path for a given scope and optional filename.
      #
      def scope_path( scope, filename = nil )
        path = File.join( scopes_path, scope.to_s )
        filename ? File.join( path, filename ) : path
      end
      
      # Log a message to the logger.
      #
      def log( message )
        logger.info "[Scrooge] #{message}"
      end
      
      # Persist the current tracker as scope or restore a previously persisted scope
      # from a given signature. 
      #
      def scope!( scope = nil )
        scope ? from_scope!( scope ) : to_scope!()
      end
      
      # Do we have a valid scope signature ?
      #
      def scope?( scope )
        scopes.include?( scope.to_s )
      end
      
      # Restore a previously persisted scope to the current tracker from a given 
      # signature.Raises Scrooge::Framework::InvalidScopeSignature if the signature
      # could not be found.
      #
      def from_scope!( scope )
        if scope?( scope )
          tracker = Scrooge::Tracker::App.new
          tracker.marshal_load( YAML.load( IO.read( scope_path( scope.to_s, 'scope.yml' ) ) ) )
          tracker
        else
          raise InvalidScopeSignature
        end  
      end
      
      # Dump the current tracker to the filesystem.
      #
      def to_scope!
        scope = Time.now.to_i
        ensure_scope_path( scope ) do
          File.open( scope_path( scope, 'scope.yml' ), 'w' ) do |out|
            YAML.dump( Scrooge::Base.profile.tracker.marshal_dump, out )
          end
        end
        scope
      end      
      
      private
       
       def ensure_scope_path( scope ) #:nodoc:
         makedir_unless_exist( scope_path( scope ) )
         yield if block_given?  
       end 
       
       def ensure_scopes_path #:nodoc:
         makedir_unless_exist( scopes_path )
         yield if block_given?
       end
           
      def makedir_unless_exist( path )
        FileUtils.makedirs( path ) unless File.exist?( path )
      end     
               
    end
  end
end