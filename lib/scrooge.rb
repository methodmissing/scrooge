$:.unshift(File.dirname(__FILE__))

require 'set'
require 'callsite'
require 'optimizations/columns/attributes_proxy'
require 'optimizations/columns/macro'
require 'optimizations/associations/macro'

module ActiveRecord
  class Base

    @@scrooge_callsites = {}
    ScroogeCallsiteSample = 0..10

    class << self
      
      # Let :scrooge_callsite be a valid find option
      #
      remove_const(:VALID_FIND_OPTIONS)
      VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset,
                             :order, :select, :readonly, :group, :having, :from, :lock, :scrooge_callsite ]

      
      # Let .find
      #
      def find(*args)
        options = args.extract_options!
        validate_find_options(options)
        set_readonly_option!(options)

        options[:scrooge_callsite] = callsite_signature( caller, options.except(:conditions, :limit, :offset) )  
        options[:include] = scrooge_callsite(options[:scrooge_callsite]).preload( options[:include] )

        case args.first
          when :first then find_initial(options)
          when :last  then find_last(options)
          when :all   then find_every(options)
          else             find_from_ids(args, options)
        end
      end      

      # Override find_ever to pass along the callsite signature
      #
      def find_every(options)
        include_associations = merge_includes(scope(:find, :include), options[:include])

        if include_associations.any? && references_eager_loaded_tables?(options)
          records = find_with_associations(options)
        else
          records = find_by_sql(construct_finder_sql(options), options[:scrooge_callsite])
          if include_associations.any?
            preload_associations(records, include_associations)
          end
        end

        records.each { |record| record.readonly! } if options[:readonly]

        records
      end

      # Determine if a given SQL string is a candidate for callsite <=> columns
      # optimization.
      #     
      def find_by_sql(sql, callsite_signature = nil)
        if scope_with_scrooge?(sql)
          find_by_sql_with_scrooge(sql, callsite_signature)
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
        
        # Computes a unique signature from a given call stack and supplementary
        # context information.
        #
        def callsite_signature( call_stack, supplementary )
          ( call_stack[ScroogeCallsiteSample] << supplementary ).hash
        end

    end  # class << self

  end
end

Scrooge::Optimizations::Columns::Macro.install!
Scrooge::Optimizations::Associations::Macro.install!