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
   
      def <<( attribute )
        GUARD.synchronize do
          Array( attribute ).each do |attr|
            attributes << attr
          end
        end  
      end     
      
      def marshal_dump
        GUARD.synchronize do
          { name() => @attributes.to_a }
        end
      end
      
      def marshal_load( data )
        GUARD.synchronize do
          @model = data.keys.first
          @attributes = Set.new( data[@model] )
          self
        end
      end
      
      def name
        @name ||= profile.orm.name( @model )
      end
      
      def table_name
        @table_name ||= profile.orm.table_name( @model )
      end
      
      def to_sql
        GUARD.synchronize do
          @attributes.map{|a| "#{table_name}.#{a.to_s}" }.join(', ')
        end
      end
      
    end
  end
end