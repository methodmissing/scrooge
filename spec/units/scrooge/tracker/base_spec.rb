require 'spec/spec_helper'

describe Scrooge::Tracker::Base do
  
  before(:each) do
    @base = Scrooge::Tracker::Base.new
  end
  
  it "should have a numeric representation" do
    @base.to_i.should equal(0)
  end
  
  it "should be able to dump itself to serializeable representation" do
    lambda{ @base.marshal_dump }.should raise_error( Scrooge::Tracker::Base::NotImplemented )
  end
  
  it "should be able to restore itself from a serializeable representation" do
    lambda{ @base.marshal_load( '' ) }.should raise_error( Scrooge::Tracker::Base::NotImplemented )
  end  
  
end