class Hash
  
  # TODO: Circumvent this hack  
  alias_method :update_without_scrooge, :update
  def update(other)
    update_without_scrooge(other.to_hash)
  end
 
end

module Scrooge
  class AttributesProxy < Hash
    attr_accessor :callsite_signature, :scrooge_columns, :fully_fetched, :klass

    def self.setup(record, scrooge_columns, klass, callsite_signature)
      hash = new.replace(record)
      hash.scrooge_columns = scrooge_columns.dup
      hash.fully_fetched = false
      hash.klass = klass
      hash.callsite_signature = callsite_signature
      hash
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
      if interesting_for_scrooge?( attr_s )
        augment_callsite!( attr_s )
        fetch_remaining
        @scrooge_columns << attr_s
      end
      super
    end

    def fetch(*args, &block)
      self[args[0]]
      super
    end

    def []=(attr_name, value)
      @scrooge_columns << attr_name.to_s
      super
    end

    def dup
      super.dup_self
    end

    def to_hash
      fetch_remaining
      super
    end

    def to_a
      fetch_remaining
      super
    end

    def delete(attr_name)
      self[attr_name]
      super
    end

    def update(hash)
      hash.fetch_remaining if hash.is_a?(Scrooge::AttributesProxy)
      @fully_fetched = true
      super
    end

    def fetch_remaining
      unless @fully_fetched
        columns_to_fetch = @klass.column_names - @scrooge_columns.to_a
        unless columns_to_fetch.empty?
          begin
            new_object = fetch_record_with_remaining_columns( columns_to_fetch )
          rescue ActiveRecord::RecordNotFound
            raise ActiveRecord::MissingAttributeError, "scrooge cannot fetch missing attribute(s) because record went away"
          end
          replace(new_object.instance_variable_get(:@attributes).merge(self))
        end
        @fully_fetched = true
      end
    end

    protected

    def fetch_record_with_remaining_columns( columns_to_fetch )
      @klass.send(:with_exclusive_scope) do
        @klass.find(self[@klass.primary_key], :select=>@klass.scrooge_sql(columns_to_fetch))
      end
    end

    def interesting_for_scrooge?( attr_s )
      has_key?(attr_s) && !@scrooge_columns.include?(attr_s)
    end

    def augment_callsite!( attr_s )
      @klass.augment_scrooge_callsite!(callsite_signature, attr_s)
    end

    def dup_self
      @scrooge_columns = @scrooge_columns.dup
      self
    end
  end
end