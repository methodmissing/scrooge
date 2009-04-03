$:.unshift(File.dirname(__FILE__))

require 'set'
require 'callsite'
require 'optimizations/columns/attributes_proxy'
require 'optimizations/columns/macro'
require 'optimizations/associations/macro'
require 'optimizations/associations/association_set'
require 'optimizations/result_sets/updateable_result_set'
require 'optimizations/result_sets/result_array'

module ActiveRecord
  class Base

    @@scrooge_callsites = {}
    ScroogeCallsiteSample = 0..10
    ScroogeMutex = Mutex.new

    # this can be set to help with testing
    cattr_accessor :scrooge_ignore_call_stack
    @@scrooge_ignore_call_stack = ($0 == "irb")

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
        @@scrooge_callsites[table_name] || ScroogeMutex.synchronize { @@scrooge_callsites[table_name] = {} }
      end

      # Fetch or setup a callsite instance for a given signature
      #
      def scrooge_callsite( callsite_signature )
        scrooge_callsites[callsite_signature] || ScroogeMutex.synchronize do
          scrooge_callsites[callsite_signature] = callsite(callsite_signature)
        end
      end

      # Flush all known callsites. Mostly a test helper.
      # 
      def scrooge_flush_callsites!
        ScroogeMutex.synchronize do
          @@scrooge_callsites[table_name] = {}
        end
      end

      private

        # Removes a single callsite
        #
        def scrooge_unlink_callsite!( callsite_signature )
          ScroogeMutex.synchronize do
            @@scrooge_callsites.delete(callsite_signature)
          end
        end 

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
        
        # Computes a unique signature from a given call stack and supplementary
        # context information.
        #
        def callsite_signature( call_stack, supplementary )
          if @@scrooge_ignore_call_stack
            supplementary.hash
          else
            ( call_stack[ScroogeCallsiteSample] << supplementary ).hash
          end
        end

    end  # class << self

  end
end

Scrooge::Optimizations::Columns::Macro.install!
Scrooge::Optimizations::Associations::Macro.install!