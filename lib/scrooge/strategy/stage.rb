module Scrooge
  module Strategy
    class Stage
      
      STATES = { :initialized => 0, 
                 :execute => 1,
                 :terminated => 2 }
      
      attr_accessor :signature,
                    :duration,
                    :payload 
                     
      def initialize( signature, options = {}, &block )                  
        @duration = options[:for] || 0 
        @payload = block
        @state = :initialized
      end
      
      def executeable?
        initialized?
      end
      
      def execute!
        begin
          @state = :execute
          result = @payload.call
          sleep( @duration )      
          result
        ensure
          @state = :terminated
        end
      end
      alias :run! :execute!
      
      def execute?
        @state == :execute
      end
      alias :running? :execute?
      
      def initialized?
        @state == :initialized
      end
      
      def terminated?
        @state == :terminated
      end
      
    end
  end
end