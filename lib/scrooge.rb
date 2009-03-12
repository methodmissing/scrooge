require 'set'

module ActiveRecord
  class ScroogeProxy < Hash                 
    
    attr_accessor :callsite,
                  :klass,
                  :columns
    
    class << self
      
      def from( callsite, klass, columns, attributes = {} )
        proxy = new
        proxy.callsite = callsite
        proxy.klass = klass
        proxy.columns = columns
        proxy.update( attributes )
        proxy    
      end
      
    end
    
    def copy_callsite
      cs = dup
      cs.update({})
      cs
    end
    
    alias_method :keys_without_scrooge, :keys    
    def keys
      columns.to_a
      #klass.column_names 
    end    
    
    def has_key?( key )
      keys_without_scrooge.include?(key)
    end   
    
    def scrooged?
      true
    end
    
    def augment!( attr_name )
      if klass.column_names.include?(attr_name)
        columns << attr_name
        klass.augment_scrooge_callsite!( @callsite, attr_name )
      end
    end

=begin    
    def keys
      scrooged? ? klass.column_names : super
    end
=end    
    def [](key)
      result = super
      augment!(key) unless result
      result
    end
    
    def delete(key)
      @columns.delete(key)
      super
    end

    def []=(key, value)
      result = super
      augment!(key) unless result
      result
    end
    
    def freeze
      @columns.freeze
      super
    end
    
  end

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
        sql =~ scrooge_select_regex && column_names.include?(self.primary_key.to_s) #&& sql !~ /LIMIT 1$/
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
        #puts "Augment #{callsite_signature.inspect} with #{attr_name.inspect}"
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
        #Thread.current[:"#{self.table_name}_scrooge_settings"] = [callsite_signature, callsite_set]
        sql = sql.gsub(scrooge_select_regex, "SELECT #{scrooge_sql(callsite_set)}")
        result = connection.select_all(sanitize_sql(sql), "#{name} Load").collect! do |record|
          instantiate( ActiveRecord::ScroogeProxy.from( callsite_signature, self, callsite_set, record ) )
          #record = instantiate(record)
          #record.scrooge_setup unless record.is_scrooged
          #record
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
          @@scrooge_select_regexes[self.table_name] ||= Regexp.compile( "SELECT (`?(?:#{table_name})?`?.?\\*)" )
        end    
    
        # Link the column to it's table.
        #
        def attribute_with_table( attr_name )
          "#{quoted_table_name}.#{attr_name.to_s}"
        end     
    
    end
    
    def scrooged?
      @attributes.respond_to?(:scrooged?) && @attributes.scrooged?
    end
    
    def missing_attribute(attr_name, stack)
      if scrooged?
        #puts "scrooged"
        #puts self.class.scrooge_sql(self.class.column_names - @attributes.columns.to_a).inspect
        reload(:select => self.class.scrooge_sql(self.class.column_names - @attributes.columns.to_a))
      else  
        #puts "not scrooged"
        raise ActiveRecord::MissingAttributeError, "missing attribute: #{attr_name}", stack
      end
    end
    
    def clone
      if scrooged?
        attrs = clone_attributes(:read_attribute_before_type_cast, @attributes.copy_callsite)
      else
        attrs = clone_attributes(:read_attribute_before_type_cast)
      end  
      attrs.delete(self.class.primary_key)
      record = self.class.new
      record.send :instance_variable_set, '@attributes', attrs
      record
    end    
    
  end
end    