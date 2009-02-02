module Scrooge
  module Storage
    class Lookup 
      
      # Centralized Resource Tracker lookup.
      # Partial API compat with Tracker::*
      
      KEY = 'scrooge_lookup'.freeze
      
      attr_accessor :resource_signatures
      
      def initialize
        @resource_signatures = Set.new
      end
      
      # Constant signature
      #
      def signature
        KEY
      end
      
      # Store the signature, and return the given resource instance
      #
      def <<( resource )
        @resource_signatures << resource.signature
        resource
      end
      
    end
  end
end