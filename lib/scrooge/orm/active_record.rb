module Scrooge
  module Orm
    class ActiveRecord < Base
      module ScroogeAttributes
        
        module SingletonMethods
          
          # Attach to generated attribute reader methods.
          #         
          def define_read_method(symbol, attr_name, column)
            if ::Scrooge::Base.profile.orm.track?
              logger.info "[Scrooge] read method #{attr_name.inspect}"
              Thread.scrooge_resource << [self.base_class, attr_name]
            end
            super(symbol, attr_name, column)
          end
          
        end
        
        module InstanceMethods        
    
          # Attach to AR::Base#read_attribute.
          #
          def read_attribute(attr_name)
            if ::Scrooge::Base.profile.orm.track?
              logger.info "[Scrooge] read attribute #{attr_name.inspect}"
              Thread.scrooge_resource << [self.class.base_class, attr_name]
            end
            super( attr_name )
          end
          
        end
      
      end
      
      class << self
        
        # Inject Scrooge ActiveRecord attribute tracking.
        #
        def install!
          profile.log "Installing ActiveRecord"
          ::ActiveRecord::Base.send( :extend, Scrooge::Orm::ActiveRecord::ScroogeAttributes::SingletonMethods )
          ::ActiveRecord::Base.send( :include, Scrooge::Orm::ActiveRecord::ScroogeAttributes::InstanceMethods )
        end
        
        # Determine if the ActiveRecord attribute tracker has already been installed.
        #
        def installed?
          begin
            ::ActiveRecord::Base.included_modules.include?( Scrooge::Orm::ActiveRecord::ScroogeAttributes )
          rescue => exception
            profile.log exception.to_s
          end
        end
        
      end
      
      # Generate scope helpers for a given resource.
      #
      def scope_to( resource )
        resource.models.each do |model|
          scope_resource_to_model( resource, model ) 
        end  
      end
      
      # Generate scope helpers for a given model and resource.
      #
      def scope_resource_to_model( resource, model )
        method_name = resource_scope_method( resource )
        klass = model.model.to_const!(false) if model.model.is_a?(String)
        unless resource_scope_method?( resource, klass ) 
          klass.instance_eval(<<-EOS, __FILE__, __LINE__)
            def #{method_name}(&block)
              with_scope( { :find => { :select => '#{model.to_sql}' } }) do
                block.call
              end 
            end  
          EOS
        end     
      end      
      
      # Returns a lookup key from a given String or AR klass 
      #
      def name( model )
        model = model.to_const!(false) if model.is_a?(String)
        model.base_class.to_s
      end
      
      # Returns a table name from a given String or AR klass 
      #
      def table_name( model )
        model = model.to_const!(false) if model.is_a?(String)
        model.table_name
      end
      
    end  
  end  
end