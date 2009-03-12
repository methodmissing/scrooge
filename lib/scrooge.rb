$:.unshift(File.dirname(__FILE__))

require 'set'
require 'attributes_proxy'

module ActiveRecord
  class Base

    @@scrooge_mutex = Mutex.new
    @@scrooge_callsites = {}
    @@scrooge_select_regexes = {}

    ScroogeBlankString = "".freeze
    ScroogeComma = ",".freeze 
    ScroogeRegexWhere = /WHERE.*/
    ScroogeCallsiteSample = 0..10

    class << self

      # Determine if a given SQL string is a candidate for callsite <=> columns
      # optimization.
      #     
      alias :find_by_sql_without_scrooge :find_by_sql
      def find_by_sql(sql)
        if scope_with_scrooge?(sql)
          find_by_sql_with_scrooge(sql)
        else
          find_by_sql_without_scrooge(sql)
        end
      end

      # Only scope n-1 rows by default.
      # Stephen: Temp. relaxed the LIMIT constraint - please advise.
      def scope_with_scrooge?( sql )
        sql =~ scrooge_select_regex && 
        column_names.include?(self.primary_key.to_s) &&
        sql !~ /INNER JOIN/
      end

      # Populate the storage for a given callsite signature
      #
      def scrooge_callsite_set!(callsite_signature, set)
        @@scrooge_callsites[self.table_name][callsite_signature] = set
      end  

      # Reference storage for a given callsite signature
      #
      def scrooge_callsite_set(callsite_signature)
        @@scrooge_callsites[self.table_name] ||= {}
        @@scrooge_callsites[self.table_name][callsite_signature]
      end

      # Augment a given callsite signature with a column / attribute.
      #
      def augment_scrooge_callsite!( callsite_signature, attr_name )
        set = set_for_callsite( callsite_signature )  # make set if needed - eg unserialized models after restart
        @@scrooge_mutex.synchronize do
          set << attr_name
        end
      end

      # Generates a SELECT snippet for this Model from a given Set of columns
      #
      def scrooge_sql( set )
        set.map{|a| attribute_with_table( a ) }.join( ScroogeComma )
      end

      private

      # Find through callsites.
      #
      def find_by_sql_with_scrooge( sql )
        callsite_signature = (caller[ScroogeCallsiteSample] << sql.gsub(ScroogeRegexWhere, ScroogeBlankString)).hash
        callsite_set = set_for_callsite(callsite_signature)
        sql = sql.gsub(scrooge_select_regex, "SELECT #{scrooge_sql(callsite_set)} FROM")
        result = connection.select_all(sanitize_sql(sql), "#{name} Load").collect! do |record|
          instantiate(Scrooge::AttributesProxy.new(record, callsite_set, self, callsite_signature))
        end
      end

      # Return an attribute Set for a given callsite signature.
      # Respects already tracked columns and ensures at least the primary key
      # if this is a fresh callsite.
      #
      def set_for_callsite( callsite_signature )
        @@scrooge_mutex.synchronize do
          callsite_set = scrooge_callsite_set(callsite_signature)
          unless callsite_set
            callsite_set = scrooge_default_callsite_set
            scrooge_callsite_set!(callsite_signature, callsite_set) 
          end
          callsite_set
        end
      end

      # Ensure that the inheritance column is defined for the callsite if
      # this is an STI klass tree. 
      #
      def scrooge_default_callsite_set
        if column_names.include?( self.inheritance_column.to_s )
          Set.new([self.primary_key.to_s, self.inheritance_column.to_s])
        else
          Set.new([self.primary_key.to_s])
        end    
      end

      # Generate a regex that respects the table name as well to catch
      # verbose SQL from JOINS etc.
      # 
      def scrooge_select_regex
        @@scrooge_select_regexes[self.table_name] ||= Regexp.compile( "SELECT (`?(?:#{table_name})?`?.?\\*) FROM" )
      end

      # Link the column to it's table.
      #
      def attribute_with_table( attr_name )
        "#{quoted_table_name}.#{attr_name.to_s}"
      end

    end  # class << self

    def scrooge_fetch_remaining
      @attributes.fetch_remaining if scrooge_attributes_proxy?
    end

    # Delete should fully load all the attributes before the @attributes hash is frozen
    #
    alias_method :delete_without_scrooge, :delete
    def delete
      scrooge_fetch_remaining
      delete_without_scrooge
    end

    # Destroy should fully load all the attributes before the @attributes hash is frozen
    #
    alias_method :destroy_without_scrooge, :destroy
    def destroy
      scrooge_fetch_remaining
      destroy_without_scrooge
    end

    # Let STI identify changes also respect callsite data.
    #
    def becomes(klass)
      returning klass.new do |became|
        became.instance_variable_set("@attributes", @attributes)
        became.instance_variable_set("@attributes_cache", @attributes_cache)
        became.instance_variable_set("@new_record", new_record?)
        if scrooge_attributes_proxy?
          self.class.scrooge_callsite_set(@attributes.callsite_signature).each do |attrib|
            became.class.augment_scrooge_callsite!(@attributes.callsite_signature, attrib)
          end
        end
      end
    end

    # Marshal
    # force a full load if needed, and remove any possibility for missing attr flagging
    #
    def _dump(depth)
      scrooge_fetch_remaining
      scrooge_dump_flag_this
      str = Marshal.dump(self)
      scrooge_dump_unflag_this
      str
    end

    # Flag Marshal dump in progress
    #
    def scrooge_dump_flag_this
      Thread.current[:scrooge_dumping_objects] ||= []
      Thread.current[:scrooge_dumping_objects] << object_id
    end

    # Flag Marhsal dump not in progress
    #
    def scrooge_dump_unflag_this
      Thread.current[:scrooge_dumping_objects].delete(object_id)
    end

    # Flag scrooge as dumping ( excuse my French )
    #
    def scrooge_dump_flagged?
      Thread.current[:scrooge_dumping_objects] && Thread.current[:scrooge_dumping_objects].include?(object_id)
    end

    # Marshal.load
    # 
    def self._load(str)
      Marshal.load(str)
    end

    # Enables us to use Marshal.dump inside our _dump method without an infinite loop
    #
    alias_method :respond_to_without_scrooge, :respond_to?
    def respond_to?(symbol, include_private=false)
      if symbol == :_dump && scrooge_dump_flagged?
        false
      else
        respond_to_without_scrooge(symbol, include_private)
      end
    end

    private
    
      def scrooge_attributes_proxy?
        @attributes.is_a?(Scrooge::AttributesProxy)
      end

  end
end
