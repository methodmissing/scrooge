module Scrooge
  class AttributesProxy
    attr_reader :callsite_signature

    def initialize(record, scrooge_columns, klass, callsite_signature)
      @attributes = record
      @scrooge_columns = scrooge_columns.dup
      @fully_fetched = false
      @klass = klass
      @callsite_signature = callsite_signature
    end

    # Delegate Hash keys to all defined columns
    #
    def keys
      @klass.column_names
    end

    # Let #has_key? consider defined columns
    #
    def has_key?(attr_name)
      keys.include?(attr_name.to_s)
    end

    alias_method :include?, :has_key?
    alias_method :key?, :has_key?

    # Lazily augment and load missing attributes
    #
    def [](attr_name)
      attr_s = attr_name.to_s
      if has_key?(attr_s) && !@scrooge_columns.include?(attr_s)
        @klass.augment_scrooge_callsite!(callsite_signature, attr_s)
        fetch_remaining
        @scrooge_columns << attr_s
      end
      @attributes[attr_s]
    end

    def fetch(*args, &block)
      self[args[0]]
      @attributes.fetch(*args, &block)
    end

    def []=(attr_name, value)
      attr_s = attr_name.to_s
      @attributes[attr_s] = value
      @scrooge_columns << attr_s
    end

    def dup
      super.dup_self
    end

    def to_a
      fetch_remaining
      @attributes.to_a
    end

    def delete(attr_name)
      self[attr_name]
      @attributes.delete(attr_name)
    end

    def update(hash)
      hash.to_hash.each do |k, v|
        self[k] = v
      end
    end

    def to_hash
      fetch_remaining
      @attributes
    end

    def freeze
      @attributes.freeze
    end

    def frozen?
      @attributes.frozen?
    end

    def fetch_remaining
      unless @fully_fetched
        columns_to_fetch = @klass.column_names - @scrooge_columns.to_a
        unless columns_to_fetch.empty?
          begin
            new_object = @klass.send(:with_exclusive_scope) do
              @klass.find(@attributes[@klass.primary_key], :select=>@klass.scrooge_sql(columns_to_fetch))
            end
          rescue ActiveRecord::RecordNotFound
            raise ActiveRecord::MissingAttributeError, "scrooge cannot fetch missing attribute(s) because record went away"
          end
          @scrooge_columns = columns_to_fetch.to_set
          @attributes = new_object.instance_variable_get(:@attributes).merge(@attributes)
        end
        @fully_fetched = true
      end
    end

    protected

    def dup_self
      @attributes = @attributes.dup
      @scrooge_columns = @scrooge_columns.dup
      self
    end
  end
end