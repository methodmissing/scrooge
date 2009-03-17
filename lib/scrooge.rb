$:.unshift(File.dirname(__FILE__))

require 'set'
require 'weakref'
require 'callsite'
require 'optimizations/columns/attributes_proxy'
require 'optimizations/columns/macro'

module ActiveRecord
  class Base

    @@scrooge_callsites = {}
    ScroogeCallsiteSample = 0..10

    class << self

      # Determine if a given SQL string is a candidate for callsite <=> columns
      # optimization.
      #     
      def find_by_sql(sql)
        if scope_with_scrooge?(sql)
          find_by_sql_with_scrooge(sql)
        else
          find_by_sql_without_scrooge(sql)
        end
      end
      
      # Expose known callsites for this model
      #      
      def scrooge_callsites
        @@scrooge_callsites[self.table_name] ||= {}
      end

      # Fetch or setup a callsite instance for a given signature
      #
      def scrooge_callsite( callsite_signature )
        @@scrooge_callsites[self.table_name] ||= {}
        @@scrooge_callsites[self.table_name][callsite_signature] ||= callsite( callsite_signature )
      end

      # Flush all known callsites.Mostly a test helper.
      #      
      def scrooge_flush_callsites!
        @@scrooge_callsites[self.table_name] = {}
      end

      private

        # Initialize a callsite
        #
        def callsite( signature )
          Scrooge::Callsite.new( self, signature )      
        end

        # Link the column to its table
        #
        def attribute_with_table( attr_name )
          "#{quoted_table_name}.#{attr_name.to_s}"
        end

    end  # class << self

  end
end

Scrooge::Optimizations::Columns::Macro.install!