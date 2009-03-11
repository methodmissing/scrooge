require 'set'

module ActiveRecord
  class Base

    attr_accessor :is_scrooged, :scrooge_callsite_signature, :scrooge_own_callsite_set

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
        saved_settings = Thread.current[:"#{self.table_name}_scrooge_settings"]
        Thread.current[:"#{self.table_name}_scrooge_settings"] = nil
        if scope_with_scrooge?(sql)
          result = find_by_sql_with_scrooge(sql)
        else
          result = find_by_sql_without_scrooge(sql)
        end
        Thread.current[:"#{self.table_name}_scrooge_settings"] = saved_settings
        result
      end

      # Only scope n-1 rows by default.
      # Stephen: Temp. relaxed the LIMIT constraint - please advise.
      def scope_with_scrooge?( sql )
        sql =~ scrooge_select_regex #&& sql !~ /LIMIT 1$/
      end

      # Populate the storage for a given callsite signature
      #
      def scrooge_callsite_set!(callsite_signature, set)
        @@scrooge_callsites[self][callsite_signature] = set
      end  

      # Reference storage for a given callsite signature
      #
      def scrooge_callsite_set(callsite_signature)
        @@scrooge_callsites[self] ||= {}
        @@scrooge_callsites[self][callsite_signature]
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
        Thread.current[:"#{self.table_name}_scrooge_settings"] = [callsite_signature, callsite_set]
        sql = sql.gsub(scrooge_select_regex, "SELECT #{scrooge_sql(callsite_set)}")
        result = connection.select_all(sanitize_sql(sql), "#{name} Load").collect! do |record|
          record = instantiate(record)
          record.scrooge_setup unless record.is_scrooged
          record
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
        @@scrooge_select_regexes[self] ||= Regexp.compile( "SELECT (`?(?:#{table_name})?`?.?\\*)" )
      end

      # Link the column to it's table.
      #
      def attribute_with_table( attr_name )
        "#{quoted_table_name}.#{attr_name.to_s}"
      end

      # Shamelessly borrowed from AR. 
      #
      def define_read_method_for_serialized_attribute(attr_name)
        method_body = <<-EOV
        def #{attr_name}
          if scrooge_attr_present?('#{attr_name}')
            unserialize_attribute('#{attr_name}')
          else
            scrooge_missing_attribute('#{attr_name}')
            unserialize_attribute('#{attr_name}')
          end
        end
        EOV
        evaluate_attribute_method attr_name, method_body
      end

      # Shamelessly borrowed from AR. 
      #
      def define_read_method(symbol, attr_name, column)
        cast_code = column.type_cast_code('v') if column
        access_code = cast_code ? "(v=@attributes['#{attr_name}']) && #{cast_code}" : "@attributes['#{attr_name}']"

        unless attr_name.to_s == self.primary_key.to_s
          access_code = access_code.insert(0, "missing_attribute('#{attr_name}', caller) unless @attributes.has_key?('#{attr_name}') && scrooge_attr_present?('#{attr_name}'); ")
        end

        if cache_attribute?(attr_name)
          access_code = "@attributes_cache['#{attr_name}'] ||= (#{access_code})"
        end
        define_with_scrooge(symbol, attr_name, access_code)
      end

      # Graceful missing attribute wrapper.
      #
      def define_with_scrooge(symbol, attr_name, access_code)
        method_def = <<-EOV
        def #{symbol}
          begin
            #{access_code}
          rescue ActiveRecord::MissingAttributeError => e
            if @is_scrooged
              scrooge_missing_attribute('#{attr_name}')
              #{access_code}
            else
              raise e
            end
          end
        end
        EOV
        evaluate_attribute_method attr_name, method_def
      end

    end  # class << self

    # Make reload load the attributes that this model thinks it needs
    # needed because reloading * will be defeated by scrooge
    #
    alias_method :reload_without_scrooge, :reload
    def reload(options = nil)
      if @is_scrooged && (!options || !options[:select])
        options = {} unless options
        options.update(:select=>self.class.scrooge_sql(@scrooge_own_callsite_set))
        @scrooge_fully_loaded = false
      end
      reload_without_scrooge(options)
    end

    # Setup scrooge settings on an AR object
    # Maintain separate record of columns that have been loaded for just this record
    # could be different from the class level columns
    #
    def scrooge_setup
      callsite_signature, callsite_set = Thread.current[:"#{self.class.table_name}_scrooge_settings"]
      @scrooge_own_callsite_set ||= callsite_set.dup
      @scrooge_callsite_signature = callsite_signature
      @is_scrooged = true
    end

    # Callbacks after_find and after_initialize can happen before instantiate returns
    # so make sure that this record is marked as scrooged first
    #
    alias_method :callback_without_scrooge, :callback
    def callback(method)
      scrooge_setup if Thread.current[:"#{self.class.table_name}_scrooge_settings"] && !new_record?
      callback_without_scrooge(method)
    end

    # Piggy back off column definitions instead
    #
    def has_attribute?(attr_name)
      self.class.column_names.include?(attr_name.to_s)
    end

    # Piggy back off column definitions instead
    #
    def attribute_names
      self.class.column_names
    end

    # Augment the callsite with a fresh column reference.
    #
    def augment_scrooge_attribute!(attr_name)
      self.class.augment_scrooge_callsite!( @scrooge_callsite_signature, attr_name )
      @scrooge_own_callsite_set << attr_name
    end

    # Handle a missing attribute - reload with all columns (once)
    # but continue record missing columns after this
    #
    def scrooge_missing_attribute(attr_name)
      logger.info "********** added #{attr_name} for #{self.class.table_name}"
      scrooge_full_reload if !@scrooge_fully_loaded
      augment_scrooge_attribute!(attr_name)
    end

    # Load the rest of the columns from the DB
    # Take care not to reload the ones we already have, they
    # might have been assigned to
    #
    def scrooge_full_reload
      @scrooge_fully_loaded = true
      reload(:select => self.class.scrooge_sql(self.class.column_names - @scrooge_own_callsite_set.to_a))
    end

    # Complete the object - load it and record all attribute names
    # Used by delete / destroy and marshal
    #
    def scrooge_complete_object
      if @is_scrooged
        scrooge_full_reload unless @scrooge_fully_loaded
        @scrooge_own_callsite_set.merge( self.class.column_names )
      end
    end

    # Wrap #read_attribute to gracefully handle missing attributes
    #
    def read_attribute(attr_name)
      attr_s = attr_name.to_s
      if scrooge_not_interested?( attr_s )
        super(attr_s)
      else
        scrooge_missing_attribute(attr_s)
        super(attr_s)
      end
    end

    # Wrap #read_attribute_before_type_cast to gracefully handle missing attributes
    #
    def read_attribute_before_type_cast(attr_name)
      attr_s = attr_name.to_s
      if scrooge_not_interested?( attr_s )
        super(attr_s)
      else
        scrooge_missing_attribute(attr_s)
        super(attr_s)
      end
    end
    
    # Does it make sense to track the given attribute ?
    #
    def scrooge_not_interested?( attr_name )
      scrooge_attr_present?(attr_name) || !self.class.column_names.include?(attr_name)
    end
     
    # Delete should fully load all the attributes before the @attributes hash is frozen
    #
    alias_method :delete_without_scrooge, :delete
    def delete
      scrooge_complete_object
      delete_without_scrooge
    end

    # Destroy should fully load all the attributes before the @attributes hash is frozen
    #
    alias_method :destroy_without_scrooge, :destroy
    def destroy
      scrooge_complete_object
      destroy_without_scrooge
    end
    
    # Is the given column known to Scrooge ?
    #
    def scrooge_attr_present?(attr_name)
      !@is_scrooged || @scrooge_own_callsite_set.include?(attr_name)
    end

    # Marshal
    # force a full load if needed, and remove any possibility for missing attr flagging
    #
    def _dump(depth)
      scrooge_complete_object
      scrooge_dump_flag_this
      str = Marshal.dump(self)
      scrooge_dump_unflag_this
      str
    end
    
    # Let STI identify changes also respect callsite data.
    #
    def becomes(klass)
      scrooge_full_reload
      returning klass.new do |became|
        became.instance_variable_set("@attributes", @attributes)
        became.instance_variable_set("@attributes_cache", @attributes_cache)
        became.instance_variable_set("@new_record", new_record?)
        if @is_scrooged
          became.instance_variable_set("@is_scrooged", true)
          became.instance_variable_set("@scrooge_fully_loaded", @scrooge_fully_loaded)
          became.instance_variable_set("@scrooge_own_callsite_set", @scrooge_own_callsite_set)
          became.instance_variable_set("@scrooge_callsite_signature", @scrooge_callsite_signature)
          @scrooge_own_callsite_set.each do |attr|
            became.class.augment_scrooge_callsite!( @scrooge_callsite_signature, attr )
          end
        end
      end
    end
    
    def scrooge_dump_flag_this
      Thread.current[:scrooge_dumping_objects] ||= []
      Thread.current[:scrooge_dumping_objects] << object_id
    end
    
    def scrooge_dump_unflag_this
      Thread.current[:scrooge_dumping_objects].delete(object_id)
    end
    
    def scrooge_dump_flagged?
      Thread.current[:scrooge_dumping_objects] && Thread.current[:scrooge_dumping_objects].include?(object_id)
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

    def self._load(str)
      Marshal.load(str)
    end
    
  end
end
