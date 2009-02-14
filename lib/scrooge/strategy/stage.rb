module Scrooge
  module Strategy
    class Stage
      
      # Represents a duration sensitive stage / phase of execution.
      
      STATES = { :initialized => 0, 
                 :execute => 1,
                 :terminated => 2 }
      
      attr_accessor :signature,
                    :duration,
                    :payload 
      
      # Requires a unique signature and stores a payload for later execution.
      #
      # Valid options is
      # * :for : the phase / stage duration, in seconds 
      #               
      def initialize( signature, options = {}, &block )
        @signature = signature                  
        @duration = options[:for] || 0 
        @payload = block
        @state = :initialized
      end
      
      # Always executeable when initialized and not yet terminated.
      #
      def executeable?
        initialized? && !terminated?
      end
      
      # Enter the :execute state, call the payload and sleep for the defined duration.
      # Returns the payload result on completion and ensures that the current state is
      # :terminated.
      #
      def execute!
        begin
          Scrooge::Base.profile.log( "Execute stage #{signature.inspect} ...", true)
          @state = :execute
          result = call!
          sleep( @duration )      
          result
        ensure
          @state = :terminated
        end
      end
      alias :run! :execute!
      
      # Are we running ?
      #
      def execute?
        @state == :execute
      end
      alias :running? :execute?
      
      # Is this stage pending execution ?
      #
      def initialized?
        @state == :initialized
      end
      
      # Has this stage already terminated ?
      #
      def terminated?
        @state == :terminated
      end
      
      private
      
        def call! #:nodoc:
          Scrooge::Base.profile.instance_eval( &@payload )
        end
      
    end
  end
end