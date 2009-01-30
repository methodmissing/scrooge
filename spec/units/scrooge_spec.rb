require 'spec/spec_helper'

describe Scrooge::Base do
  
  before(:each) do
    @base = Scrooge::Base
  end
  
  it "should be able to instantiate it's profile" do
    @base.profile.class.should == Scrooge::Profile
  end
  
end