require 'spec/spec_helper'

describe "Scrooge::Core::Thread singleton" do
  
  it "should be able to yield the current scrooge resource" do
    Thread.scrooge_resource.class.should equal( Scrooge::Tracker::Resource )
  end
  
  it "should be able to reset the current scrooge resource" do
    @resource = Thread.scrooge_resource
    Thread.reset_scrooge_resource!
    @resource.object_id.should_not equal( Thread.scrooge_resource.object_id )
  end
  
end