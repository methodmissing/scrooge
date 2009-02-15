module Scrooge
  module Strategy
    
    autoload :Controller, 'scrooge/strategy/controller'
    autoload :Stage, 'scrooge/strategy/stage'
    autoload :Scope, 'scrooge/strategy/scope'
    autoload :Track, 'scrooge/strategy/track'
    autoload :TrackThenScope, 'scrooge/strategy/track_then_scope'

    class Base
      
      class NoStages < StandardError
      end
      
      @@stages = Hash.new( [] )
      @@stages[self.name] = []
      
      attr_reader :thread
      
      class << self
        
        # Stage definition macro.
        #
        # stage :track, :for => 10.minutes do
        #   ....
        # end
        #
        def stage( signature, options = {}, &block )
          @@stages[self.name] << Scrooge::Strategy::Stage.new( signature, options, &block )
        end
        
        # List all defined stages for this klass.
        #
        def stages
          @@stages[self.name]
        end
        
        # Are there any stages defined ?
        #
        def stages?
          !stages.empty?
        end
        
        # Test teardown helper.
        #
        def flush!
          @@stages[self.name] = []
        end
        
      end
      
      # Requires at least one stage definition.
      #
      def initialize
        raise NoStages unless self.class.stages?
      end 
      
      # Piggy back on stages defined for this klass.
      #
      def stages
        self.class.stages
      end
      
      # Enforce this strategy
      #
      def execute!
        if Scrooge::Base.profile.enabled?
          @thread = Scrooge::Strategy::Controller.new( self ).run!
        end
      end
      
    end
  end
end