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
      
      # Dump to a SQL SELECT snippet.
      #
      def to_sql
        GUARD.synchronize do
          @attributes.map{|a| "#{table_name}.#{a.to_s}" }.join(', ')
        end
      end
      
    end
  end
end