module Scrooge
  module Strategy
    
    autoload :Controller, 'scrooge/strategy/controller'
    autoload :Stage, 'scrooge/strategy/stage'

    class Base
      
      autoload :Scope, 'scrooge/strategy/scope'
      autoload :Track, 'scrooge/strategy/track'
      autoload :TrackThenScope, 'scrooge/strategy/track_then_scope'
      
      class NoStages < StandardError
      end
      
      @@stages = {}
      @@stages[self.name] = []
      
      class << self
        
        # stage :track, :for => 10.minutes do
        #   ....
        # end
        #
        def stage( signature, options = {}, &block )
          @@stages[self.name] << Scrooge::Strategy::Stage.new( signature, options, &block )
        end
        
        def stages
          @@stages[self.name]
        end
        
        def stages?
          !stages.empty?
        end
        
        def flush!
          @@stages[self.name] = []
        end
        
      end
      
      def initialize
        raise NoStages unless stages?
      end 
      
      def stages?
        self.class.stages?
      end
      
      def stages
        self.class.stages
      end
      
    end
  end
end