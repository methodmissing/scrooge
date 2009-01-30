require 'spec/spec_helper'

describe Scrooge::Core::String do
  
  before(:each) do
    @string = 'active_record'
  end
  
  it "should be able to convert itself to a constant" do
    @string.to_const().should == 'ActiveRecord'
  end
  
end