module Scrooge
  module Strategy
    class Controller
      
      attr_accessor :strategy
      attr_reader :thread
                    
      def initialize( strategy )
        @strategy = strategy
      end
      
      # Execute a given strategy
      #
      def run!
        @thread = Thread.new do
          Thread.current.abort_on_exception = true
          stages.map do |stage|
            stage.execute!
          end
        end
      end
      
      private
      
        def stages #:nodoc:
          @strategy.stages
        end
      
    end
  end
end