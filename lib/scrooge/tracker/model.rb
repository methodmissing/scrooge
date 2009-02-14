module Scrooge
  module Tracker
    class Model < Base
      
      GUARD = Monitor.new
      
      attr_accessor :model,
                    :attributes 

      def initialize( model )
        super()
        @model = model
        @attributes = Set.new 
      end

      # Merge this Tracker with another Tracker for the same model ( multi-process aggregation ) 
      #
      def merge( other_model )
        return unless other_model
        attributes.merge( other_model.attributes )
      end

      # Has any Attributes been tracked ? 
      #
      def any?
        GUARD.synchronize do
          !@attributes.empty?
        end  
      end
   
      # Add a Model attribute to this tracker.
      #
      def <<( attribute )
        GUARD.synchronize do
          Array( attribute ).each do |attr|
            attributes << attr
          end
        end  
      end     
      
      def marshal_dump #:nodoc:
        GUARD.synchronize do
          { name() => @attributes.to_a }
        end
      end
      
      def marshal_load( data ) #:nodoc:
        GUARD.synchronize do
          @model = data.keys.first
          @attributes = Set.new( data[@model] )
          self
        end
      end
      
      # Memoize the name lookup.
      #
      def name
        @name ||= profile.orm.name( @model )
      end
      
      # Memoize the table name lookup.
      #
      def table_name
        @table_name ||= profile.orm.table_name( @model )
      end
      
      # Memoize the primary key lookup.
      #
      def primary_key
        @primary_key ||= profile.orm.primary_key( @model )
      end
      
      # Dump to a SQL SELECT snippet.
      #
      def to_sql
        GUARD.synchronize do
          attributes_with_primary_key().map{|a| "#{table_name}.#{a.to_s}" }.join(', ')
        end
      end
      
      def inspect #:nodoc:
        "#<#{name()} #{attributes_for_inspect}>"
      end
      
      private
       
        def attributes_for_inspect #:nodoc:
          @attributes.map{|a| ":#{a}" }.join(', ')
        end
      
        def attributes_with_primary_key #:nodoc:
          @attributes << primary_key
        end
      
    end    
  end
end