module Scrooge
  class Callsite
    
    # Represents a Callsite and is a container for any columns and 
    # associations referenced at the callsite.
    #
    
    Mtx = Mutex.new  # mutex should perhaps be per-instance at the expense of a little memory

    attr_accessor :klass,
                  :signature,
                  :columns,
                  :associations
    
    def initialize( klass, signature )
      @klass = klass
      @signature = signature
    end
    
    # Flag a column as seen
    #
    def column!( column )
      columns && Mtx.synchronize { @columns << column }
    end
    
    # Flag an association as seen
    # association should be an AssociationReflection object
    #
    def association!(association, record_id)
      if preloadable_association?(association.name)
        associations.register(association, record_id)
      end
    end
    
    def inspect
      "<##{@klass.name} :select => '#{@klass.scrooge_select_sql( columns )}', :include => [#{associations_for_inspect}]>"
    end
    
    # Lazy init default columns
    #
    def default_columns
      @default_columns || Mtx.synchronize { @default_columns = setup_columns }
    end
    
    # Lazy init columns
    #
    def columns
      @columns || default_columns && Mtx.synchronize { @columns = @default_columns.dup } 
    end
  
    # Lazy init associations
    #
    def associations
      @associations || Mtx.synchronize { @associations = setup_associations }
    end
    
    def has_associations?
      @associations
    end
    
    # Analyze previously collected information
    # and reset ready for a new query
    #
    def reset
      if has_associations?
        associations.reset
      end
    end
    
    def register_result_set(result_set)
      if has_associations?
        associations.register_result_set(result_set)
      end
    end
    
    private
    
      def associations_for_inspect
        if has_associations?
          associations.to_preload.map{|a| ":#{a.to_s}" }.join(', ')
        else
          ""
        end
      end
    
      # Only register associations that isn't polymorphic or a collection
      #
      def preloadable_association?( association )
        @klass.preloadable_associations.include?( association.to_sym )
      end
    
      # Is the table a container for STI models ?
      # 
      def inheritable?
        @klass.columns_hash.has_key?( inheritance_column )
      end
    
      # Ensure that at least the primary key and optionally the inheritance
      # column ( for STI ) is set. 
      #
      def setup_columns
        if inheritable?
          SimpleSet.new([primary_key, inheritance_column])
        else
          primary_key.blank? ? SimpleSet.new : SimpleSet.new([primary_key])
        end    
      end
    
      # Start with no registered associations
      #
      def setup_associations
        Optimizations::Associations::AssociationSet.new
      end
    
      # Memoize a string representation of the inheritance column
      #
      def inheritance_column
        @inheritance_column ||= @klass.inheritance_column.to_s
      end

      # Memoize a string representation of the primary
      #    
      def primary_key
        @primary_key ||= @klass.primary_key.to_s
      end    
    
  end
end