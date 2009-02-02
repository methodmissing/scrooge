require 'spec/spec_helper'

describe "Scrooge::Storage::Base singleton" do
  
  before(:each) do
    @base = Scrooge::Storage::Base
  end
  
  it "should be able to instantiate a storage backend from a given storage signature" do
    @base.instantiate( :memory ).class.should equal(Scrooge::Storage::Memory)
  end
  
end

describe Scrooge::Storage::Base do
  
  before(:each) do
    @base = Scrooge::Storage::Base.new
    @tracker = mock('tracker')
    @tracker.stub!(:signature).and_return('signature')
  end

  it "should be able to read from the storage backend" do
    lambda{ @base.read( @tracker ) }.should raise_error( Scrooge::Storage::Base::NotImplemented )
  end
  
  it "should be able to write to the storage backend" do
    lambda{ @base.write( @tracker ) }.should raise_error( Scrooge::Storage::Base::NotImplemented )
  end    
  
  it "should be able to yield a namespaced storage key" do
    @base.expand_key( "signature" ).should eql( "scrooge_storage/signature" )
  end
  
end  