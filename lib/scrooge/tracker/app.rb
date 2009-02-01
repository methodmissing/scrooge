module Scrooge
  module Tracker
    class App < Scrooge::Tracker::Base
      
      GUARD = Monitor.new      
      
      attr_accessor :resources
      
      def initialize
        super()
        @resources = Set.new
      end
            
      def <<( resource )
        GUARD.synchronize do
          @resources << setup_resource( resource )
        end
      end
      
      def marshal_dump
        GUARD.synchronize do
          { environment() => dumped_resources() }
        end
      end
      
      def marshal_load( data )
        GUARD.synchronize do
          @resources = Set.new( restored_resources( data ) )
        end
        self
      end
      
      def track( resource )
        profile.log "Track with resource #{resource.inspect}"
        begin
          yield
        ensure
          self << resource
        end     
      end
      
      private
      
        def setup_resource( resource )
          GUARD.synchronize do
            resource_for( resource ) || resource
          end
        end
      
        def environment #:nodoc:
          profile.framework.environment
        end
      
        def restored_resources( data ) #:nodoc:
          GUARD.synchronize do
            data[environment()].map do |resource|
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
      
        def resource_for( resource )
          @resources.detect{|r| r.signature == resource.signature }
        end
      
    end
  end
end