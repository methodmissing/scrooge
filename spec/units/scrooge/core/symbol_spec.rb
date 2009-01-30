require 'spec/spec_helper'

describe Scrooge::Core::Symbol do
  
  before(:each) do
    @symbol = :active_record
  end
  
  it "should be able to convert itself to a constant" do
    @symbol.to_const().should == 'ActiveRecord'
  end
  
end