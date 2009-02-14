module Scrooge
  module Tracker
    class Resource < Base
      
      # A Resource tracker is scoped to a
      #
      # * controller
      # * action
      # * request method
      # * content type
      #
      # and is a container for any Models referenced during the active
      # request / response cycle.
      
      GET = /get/i
      
      GUARD = Monitor.new
            
      attr_accessor :controller,
                    :action,
                    :method,
                    :format,
                    :models      
      
      def initialize
        super()
        @models = Set.new
        yield self if block_given?
      end

      # Merge this Tracker with another Tracker for the same resource ( multi-process / cluster aggregation ) 
      #      
      def merge( other_resource )
        return unless other_resource
        models.merge( other_resource.models )
        models.each do |model|
          model.merge( other_resource.model( model ) )
        end
      end

      # Has any Models been tracked ? 
      #
      def any?
        GUARD.synchronize do
          !@models.empty?
        end  
      end
      
      # Search for a given model instance
      #
      def model( model )
        models.detect{|m| m.name == model.name }
      end
      
      # Generates a signature / lookup key.
      #
      def signature
        @signature ||= "#{controller.to_s}_#{action.to_s}_#{method.to_s}"
      end
      
      # Only track GET requests
      #
      def trackable?
        !( method || '' ).to_s.match( GET ).nil?
      end
      
      # Add a Model to this resource.
      #
      def <<( model )
        GUARD.synchronize do
          @models << track_model_from( model )
        end
      end
      
      def marshal_dump #:nodoc:
        GUARD.synchronize do
          { signature => { :controller => @controller,
                           :action => @action,
                           :method => @method,
                           :format => @format,
                           :models => dumped_models() } }
        end
      end      
      
      def marshal_load( data ) #:nodoc:
        GUARD.synchronize do
          data = data.to_a.flatten.last
          @controller = data[:controller]
          @action = data[:action]
          @method = data[:method]
          @format = data[:format]
          @models = restored_models( data[:models] )
          self
        end  
      end
      
      # Yields a collection of Rack middleware to scope Model attributes to the
      # tracked dataset.
      #
      def middleware
        @middleware ||= begin
          GUARD.synchronize do
            models.map do |model|
              middleware_for_model( model )
            end
          end  
        end
      end      
      
      # Return a valid Rack middleware instance for a given model.
      #
      def middleware_for_model( model )
        resource = self  
        profile.orm.scope_resource_to_model( resource, model )
        klass = Class.new
        klass.class_eval(<<-EOS, __FILE__, __LINE__)
          
          class << self
            
            def inspect
              "#<Scrooge::Middleware #{model.inspect}>"
            end
            
            # Around Filter compatible implementation for Rails as Dispatcher is 
            # the root Rack application and as such don't provide access to the Rails
            # Routing internals from other middleware.
            #
            def filter( controller, &block )
              #{model.model.to_s}.#{profile.orm.resource_scope_method( resource ).to_s} do
                Scrooge::Base.profile.log "Scope for Model #{model.inspect}"
                block.call
              end
            end
            
          end
          
          def initialize(app)
            @app = app
          end

          def call(env)
            if scope?( env )
              #{model.model.to_s}.#{profile.orm.resource_scope_method( resource ).to_s} do
                @app.call(env)
              end
            else
              @app.call(env)
            end  
          end
          
          private
            
            def scope?( env )
              Scrooge::Base.profile.orm.resource_scope_method( resource( env ) ) == :#{profile.orm.resource_scope_method( resource ).to_s}                 
            end  
            
            def resource( env )
              Scrooge::Base.profile.framework.resource( env )
            end
          
        EOS
        klass
      end
      
      def inspect #:nodoc:
        "#<#{@method.to_s.upcase} :#{@controller}/#{@action} (#{@format})\n#{models_for_inspect()}"
      end
      
      private
      
        def track_model_from( model ) #:nodoc:
          model.is_a?( Array ) ? model_from_enumerable( model ) : setup_model( model )
        end
      
        def model_from_enumerable( model ) #:nodoc:
          model, attribute = model
          model = setup_model( model )
          model << attribute
          model
        end
      
        def models_for_inspect #:nodoc:
          models.map{|m| " - #{m.inspect}" }.join( "\n" )
        end
      
        def dumped_models #:nodoc:
          GUARD.synchronize do
            @models.to_a.map{|m| m.marshal_dump }
          end
        end
        
        def restored_models( models ) #:nodoc:
          GUARD.synchronize do
            models.map do |model|
              m = model.keys.first # TODO: cleanup
              Model.new( m ).marshal_load( model )
            end.to_set
          end  
        end
        
        def setup_model( model ) #:nodoc:
          GUARD.synchronize do
            if model.is_a?( Scrooge::Tracker::Model )
              model
            else
              model_for( model ) || Scrooge::Tracker::Model.new( model )
            end
          end       
        end
      
        def model_for( model ) #:nodoc:
          @models.detect{|m| m.model.name == model.name }
        end
      
    end
  end
end