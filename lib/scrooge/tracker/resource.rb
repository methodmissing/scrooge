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

      # Has any Models been tracked ? 
      #
      def any?
        GUARD.synchronize do
          !@models.empty?
        end  
      end
      
      # Generates a signature / lookup key.
      #
      def signature
        @signature ||= "#{controller.to_s}_#{action.to_s}_#{method.to_s}_#{format.to_s}".gsub( '/', '_' )
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
          if model.is_a?( Array )
            model, attribute = model
            model = setup_model( model )
            model << attribute
          else
            model = setup_model( model )
          end
          @models << model
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
          def initialize(app)
            @app = app
          end

          def call(env)
            #{model.model.to_s}.#{profile.orm.resource_scope_method( resource ).to_s} do
              @app.call(env)
            end
          end
        EOS
        klass
      end
      
      def inspect #:nodoc:
        "#<#{@method.to_s.upcase} :#{@controller}/#{@action} #{@content_type}\n#{models_for_inspect()}"
      end
      
      private
      
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
            end
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
          @models.detect{|m| m.model == model }
        end
      
    end
  end
end