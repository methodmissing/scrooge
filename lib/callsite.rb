module Scrooge
  class Callsite
    
    # Represents a Callsite and is a container for any columns and 
    # associations ( coming soon ) referenced at the callsite.
    #
    
    Mutex = Mutex.new
    
    attr_accessor :klass,
                  :signature,
                  :columns,
                  :associations
    
    def initialize( klass, signature )
      @klass = klass
      @signature = signature
      @columns = setup_columns 
      @associations = setup_associations
    end
    
    # Flag a column as seen
    #
    def column!( column )
      Mutex.synchronize do 
        @columns << column
      end
    end
    
    # Flag an association as seen
    #
    def association!( association )
      Mutex.synchronize do
        @associations << association
      end
    end
    
    private
    
      # Is the table a container for STI models ?
      # 
      def inheritable?
        @klass.column_names.include?( inheritance_column )
      end
    
      # Ensure that at least the primary key and optionally the inheritance
      # column ( for STI ) is set. 
      #
      def setup_columns
        if inheritable?
          Set.new([primary_key, inheritance_column])
        else
          Set.new([primary_key])
        end    
      end
    
      # Stubbed for future use
      #
      def setup_associations
        Set.new
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