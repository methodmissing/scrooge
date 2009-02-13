require 'set'

module Scrooge
  module Tracker
    
    autoload :App, 'scrooge/tracker/app'
    autoload :Resource, 'scrooge/tracker/resource'
    autoload :Model, 'scrooge/tracker/model'
    
    class Base < Scrooge::Base
      include Comparable      
      
      # Scrooge Tracker base class.
      
      class NotImplemented < StandardError
      end
      
      class << self
        
        # Marshal helper.
        #
        def load( data )
          new.marshal_load( data )
        end
        
      end
      
      attr_accessor :counter
      
      def initialize
        @counter = 0
      end
      
      def to_i
        @counter  
      end
      
      # Requires subclasses to implement a custom marshal_dump
      #
      def marshal_dump
        raise NotImplemented
      end

      # Requires subclasses to implement a custom marshal_load
      #      
      def marshal_load( data )
        raise NotImplemented
      end
      
      # Compare trackers through their Marshal representations.
      #
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