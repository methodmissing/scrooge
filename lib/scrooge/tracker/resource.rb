module Scrooge
  module Tracker
    class Resource < Base
      
      GET = /get/i
            
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
      
      def signature
        @signature ||= "#{controller.to_s}_#{action.to_s}_#{method.to_s}_#{format.to_s}"
      end
      
      def trackable?
        !( method || '' ).to_s.match( GET ).nil?
      end
      
      def <<( model )
        if model.is_a?( Array )
          model, attribute = model
          model = setup_model( model )
          model << attribute
        else
          model = setup_model( model )
        end
        @models << model
      end
      
      def marshal_dump
        { signature => { :controller => @controller,
                         :action => @action,
                         :method => @method,
                         :format => @format,
                         :models => dumped_models() } }
      end      
      
      def marshal_load( data )
        data = data.to_a.flatten.last
        @controller = data[:controller]
        @action = data[:action]
        @method = data[:method]
        @format = data[:format]
        @models = data[:models]
        self
      end
      
      def middlewares
        
      end
      
      def middleware
        @middleware ||= begin
          models.map do |model|
            middleware_for_model( model )
          end
        end
      end      
      
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
      
      private
      
        def dumped_models #:nodoc:
          @models.to_a.map{|m| m.marshal_dump }
        end
        
        def setup_model( model )
          if model.is_a?( Scrooge::Tracker::Model )
            model
          else
            Scrooge::Tracker::Model.new( model )
          end     
        end
      
    end
  end
end