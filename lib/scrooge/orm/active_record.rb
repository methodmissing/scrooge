module Scrooge
  module Orm
    class ActiveRecord < Base
      module ScroogeAttributes
        
        module SingletonMethods
          
          private
     
            # Attach to generated attribute reader methods.
        
            def define_read_method(symbol, attr_name, column)
              register_with_scrooge!( attr_name, 'define read method' )
              super(symbol, attr_name, column)
            end
          
            def define_read_method_for_time_zone_conversion(attr_name)
              register_with_scrooge!( attr_name, 'define read method for time zone conversion' )
              super(attr_name)
            end

            def define_read_method_for_serialized_attribute(attr_name)
              register_with_scrooge!( attr_name, 'define read method for serialized attribute' )
              super(attr_name)
            end  

            private 
            
              def register_with_scrooge!( attr_name, caller ) #:nodoc:
                if ::Scrooge::Base.profile.orm.track?
                  ::Scrooge::Base.profile.log( "Register attribute #{attr_name.inspect} from #{caller}" ) if ::Scrooge::Base.profile.verbose?
                  Thread.scrooge_resource << [self.base_class, attr_name]
                end
              end

        end
        
        module InstanceMethods        
    
          # Attach to AR::Base#read_attribute.
          #
          def read_attribute(attr_name)
            register_with_scrooge!( attr_name, 'read attribute' )
            super( attr_name )
          end

          # Attach to AR::Base#read_attribute_before_typecast.
          #
          def read_attribute_before_type_cast(attr_name)
            register_with_scrooge!( attr_name, 'read attribute before type cast' )
            super(attr_name)
          end
          
          private
          
            def register_with_scrooge!( attr_name, caller ) #:nodoc:
              if ::Scrooge::Base.profile.orm.track?
                ::Scrooge::Base.profile.log( "Register attribute #{attr_name.inspect} from #{caller}" ) if ::Scrooge::Base.profile.verbose?
                Thread.scrooge_resource << [self.class.base_class, attr_name]
              end
            end
            
            def missing_attribute(attr_name, stack) #:nodoc:
              if Scrooge::Base.profile.raise_on_missing_attribute?
                super(attr_name, stack)
              else
                logger.info "[Scrooge] missing attribute #{attr_name.to_s}"
                reload( :select => '*' )
              end    
            end
          
        end
      
      end
      
      class << self
        
        # Inject Scrooge ActiveRecord attribute tracking.
        #
        def install!
          ::ActiveRecord::Base.send( :extend, Scrooge::Orm::ActiveRecord::ScroogeAttributes::SingletonMethods )
          ::ActiveRecord::Base.send( :include, Scrooge::Orm::ActiveRecord::ScroogeAttributes::InstanceMethods )
        end
        
        # Determine if the ActiveRecord attribute tracker has already been installed.
        #
        def installed?
          begin
            ::ActiveRecord::Base.included_modules.include?( Scrooge::Orm::ActiveRecord::ScroogeAttributes )
          rescue => exception
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
        klass = klass_for_model( model )
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
        model.respond_to?(:base_class) ? model.base_class.to_s : model.to_s
      end
      
      # Returns a table name from a given String or AR klass 
      #
      def table_name( model )
        model = model.to_const!(false) if model.is_a?(String)
        model.table_name
      end
      
      # Returns a primary key from a given String or AR klass 
      #
      def primary_key( model )
        model = model.to_const!(false) if model.is_a?(String)
        model.primary_key
      end      
      
      private
      
        def klass_for_model( model ) #:nodoc:
          model.model.is_a?(String) ? model.model.to_const!(false) : model.model
        end
      
    end  
  end  
end