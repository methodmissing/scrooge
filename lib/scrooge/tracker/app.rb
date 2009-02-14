module Scrooge
  module Tracker
    class App < Scrooge::Tracker::Base
      
      # Application container for various Resources.
      
      GUARD = Monitor.new      
      
      AGGREGATION_BUCKET = 'scrooge_tracker_aggregation'.freeze
      
      attr_accessor :resources
      
      def initialize
        super()
        @resources = Set.new
      end
      
      # Push this tracker instance to the framework's cache store. 
      # A synchronization signature unique for this Process is also logged in a synchronization 
      # bucket which maintain references to each Process's tracker.
      #
      def synchronize!
        GUARD.synchronize do
          write_cache( syncronization_signature, Marshal.dump( self ) )
          register_synchronization_signature!
        end
      end
      
      # Process previously synchronized tracking data by recursively merging all trackers from
      # all Processes to have a Tracker representative of the whole cluster.
      #
      def aggregate!
        GUARD.synchronize do
          read_cache( AGGREGATION_BUCKET ).each do |tracker|
            tracker_data = read_cache( tracker )
            merge( self.class.load( tracker_data ) )
          end  
        end  
      end
      
      # Merge this Tracker with another Tracker ( multi-process aggregation ) 
      #      
      def merge( other_tracker )
        return unless other_tracker
        resources.merge( other_tracker.resources )
        resources.each do |res|
          resource.merge( other_tracker.resource( res )  )
        end
      end

      # Find a given resource instance
      #      
      def resource( resource )
        resources.detect{|r| r.signature == resource.signature }
      end
      
      # Has any Resources been tracked ? 
      #
      def any?
        GUARD.synchronize do
          !@resources.empty?
        end  
      end
      
      # Add a Resource instance to this tracker.
      #      
      def <<( resource )
        GUARD.synchronize do
          @resources << setup_resource( resource )
        end
      end
      
      def marshal_dump #:nodoc:
        GUARD.synchronize do
          dumped_resources()
        end
      end
      
      def marshal_load( data ) #:nodoc:
        GUARD.synchronize do
          @resources = Set.new( restored_resources( data ) )
        end
        self
      end
      
      # Track a given Resource.
      #
      def track( resource )
        profile.log "Track with resource #{resource.inspect}"
        begin
          yield
        ensure
          self << resource if resource.any?
        end     
      end
      
      def inspect #:nodoc:
        if any?
          @resources.map{|r| r.inspect }.join( "\n\n" )
        else
          super
        end  
      end
      
      # If we've seen this resource before, return the original, else, returns
      # the given resource.
      #
      def resource_for( res )
        resource( res ) || res
      end
      
      private
      
        def read_cache( key ) #:nodoc:
          Scrooge::Base.profile.framework.read_cache( key )
        end
        
        def write_cache( key, value ) #:nodoc:
          Scrooge::Base.profile.framework.write_cache( key, value )
        end
      
        def register_synchronization_signature! #:nodoc:
          if bucket = read_cache( AGGREGATION_BUCKET )
            write_cache( AGGREGATION_BUCKET, [synchronization_signature] )
          else
            write_cache( AGGREGATION_BUCKET, (bucket << synchronization_signature) )
          end   
        end
      
        def synchronization_signature #:nodoc:
          @synchronization_signature ||= "#{Thread.current.object_id}_#{Process.pid}_#{rand(1000000)}"
        end
      
        def setup_resource( resource ) #:nodoc:
          GUARD.synchronize do
            resource_for( resource )
          end
        end
      
        def environment #:nodoc:
          profile.framework.environment
        end
      
        def restored_resources( data ) #:nodoc:
          GUARD.synchronize do
            data.map do |resource|
              Resource.new.marshal_load( resource )
            end
          end
        end
      
        def dumped_resources #:nodoc:
          GUARD.synchronize do
            @resources.to_a.map do |resource|
              resource.marshal_dump
            end
          end
        end
            
    end
  end
end