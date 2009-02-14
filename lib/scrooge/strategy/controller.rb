module Scrooge
  module Strategy
    class Controller
      
      attr_accessor :strategy
                    
      def initialize( strategy )
        @strategy = strategy
      end
      
      def run!
        Thread.new do
          stages.map do |stage|
            stage.execute!
          end
        end.value
      end
      
      private
      
        def stages #:nodoc:
          @strategy.stages
        end
      
    end
  end
end