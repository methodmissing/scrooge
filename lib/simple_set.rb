module Scrooge

  class SimpleSet < Hash
 
    class << self
      ##
      # Creates a new set containing the given objects
      #
      # @return [SimpleSet] The new set
      #
      # @api public
      def [](*ary)
        new(ary)
      end
    end
 
    ##
    # Create a new SimpleSet containing the unique members of _arr_
    #
    # @param [Array] arr Initial set values.
    #
    # @return [Array] The array the Set was initialized with
    #
    # @api public
    def initialize(arr = [])
      Array(arr).each {|x| self[x] = true}
    end
 
    ##
    # Add a value to the set, and return it
    #
    # @param [Object] value Value to add to set.
    #
    # @return [SimpleSet] Receiver
    #
    # @api public
    def <<(value)
      self[value] = true
      self
    end
 
    ##
    # Merge _arr_ with receiver, producing the union of receiver & _arr_
    #
    #   s = Extlib::SimpleSet.new([:a, :b, :c])
    #   s.merge([:c, :d, :e, f])  #=> #<SimpleSet: {:e, :c, :f, :a, :d, :b}>
    #
    # @param [Array] arr Values to merge with set.
    #
    # @return [SimpleSet] The set after the Array was merged in.
    #
    # @api public
    def merge(arr)
      super(arr.inject({}) {|s,x| s[x] = true; s })
    end
    alias_method :|, :merge
 
    ##
    # Invokes block once for each item in the set. Creates an array
    # containing the values returned by the block.
    #
    #   s = Extlib::SimpleSet.new([1, 2, 3])
    #   s.collect {|s| s + 1}  #=> [2, 3, 4]
    #
    # @return [Array] The values returned by the block
    #
    # @api public
    def collect(&block)
      keys.collect(&block)
    end
    alias_method :map, :collect
 
    ##
    # Get a human readable version of the set.
    #
    #   s = SimpleSet.new([:a, :b, :c])
    #   s.inspect                 #=> "#<SimpleSet: {:c, :a, :b}>"
    #
    # @return [String] A human readable version of the set.
    #
    # @api public
    def inspect
      "#<SimpleSet: {#{keys.map {|x| x.inspect}.join(", ")}}>"
    end
 
    # def to_a
    alias_method :to_a, :keys
 
  end # SimpleSet

end