module Scrooge
  module Strategy
    class Controller
      
      attr_accessor :strategy,
                    
      
      def initialize( strategy )
        @strategy = strategy
      end
      
      def run!
        Thread.new do
          stages.each do |stage|
            stage.execute!
          end
        end
      end
      
      private
      
        def stages
          @strategy.stages
        end
      
    end
  end
end