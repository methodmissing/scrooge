require 'set'

module Scrooge
  module Tracker
    
    autoload :App, 'scrooge/tracker/app'
    autoload :Resource, 'scrooge/tracker/resource'
    autoload :Model, 'scrooge/tracker/model'
    
    class Base < Scrooge::Base
      include Comparable      
      
      class NotImplemented < StandardError
      end
      
      attr_accessor :counter
      
      def initialize
        @counter = 0
      end
      
      def to_i
        @counter  
      end
      
      def marshal_dump
        raise NotImplemented
      end
      
      def marshal_load( data )
        raise NotImplemented
      end
      
      def ==( tracker )
        compare_to( tracker )
      end
      alias :eql? :==
      alias :<=> :==
      
      private
        
        def compare_to( tracker ) #:nodoc:
          marshal_dump == tracker.marshal_dump
        end
          
    end
  end
end