require 'spec/spec_helper'

describe Scrooge::Storage::Lookup do
  
  before(:each) do
    @lookup = Scrooge::Storage::Lookup.new
    @resource = mock('resource')
    @resource.stub!(:signature).and_return( 'signature' )
  end
  
  it "should be able to return a signature for API compat with Tracker::*" do
    @lookup.signature.should eql( 'scrooge_lookup' )
  end
  
  it "should be able to add resources to itself" do
    lambda{ @lookup << @resource  }.should change( @lookup.resource_signatures, :size ).from(0).to(1)   
    ( @lookup << @resource ).signature.should eql( 'signature' )
  end
  
end