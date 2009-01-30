module Scrooge
  module Tracker
    class Model < Base
      
      attr_accessor :model,
                    :attributes 

      def initialize( model )
        super()
        @model = model
        @attributes = Set.new 
      end
   
      def <<( attribute )
        Array( attribute ).each do |attr|
          attributes << attr
        end
      end     
      
      def marshal_dump
        { name() => @attributes.to_a }
      end
      
      def marshal_load( data )
        @attributes = Set.new( data[name()] )
        self
      end
      
      def name
        @name ||= profile.orm.name( @model )
      end
      
      def table_name
        @table_name ||= profile.orm.table_name( @model )
      end
      
      def to_sql
        @attributes.map{|a| "#{table_name}.#{a.to_s}" }.join(', ')
      end
      
    end
  end
end