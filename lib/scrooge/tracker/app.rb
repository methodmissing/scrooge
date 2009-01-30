module Scrooge
  module Tracker
    class App < Scrooge::Tracker::Base
      
      attr_accessor :resources
      
      def initialize
        super()
        @resources = Set.new
      end
            
      def <<( resource )
        @resources << resource
      end
      
      def marshal_dump
        { environment() => dumped_resources() }
      end
      
      def marshal_load( data )
        @resources = Set.new( restored_resources( data ) )
        self
      end
      
      def track( resource )
        if profile.track? && resource.trackable?
          with_tracking( resource ) do
            yield
          end
        else
          yield
        end       
      end
      
      private
      
        def with_tracking( resource )
          Thread.current[:scrooge_resource] = resource
          yield 
        ensure
          Thread.current[:scrooge_resource] = nil  
        end
      
        def environment #:nodoc:
          profile.framework.environment
        end
      
        def restored_resources( data ) #:nodoc:
          data[environment()].map do |resource|
            Resource.new.marshal_load( resource )
          end
        end
      
        def dumped_resources #:nodoc:
          @resources.to_a.map do |resource|
            resource.marshal_dump
          end
        end
      
    end
  end
end