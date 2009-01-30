require 'spec/spec_helper'

describe Scrooge::Storage::Cache do
  
  before(:each) do
    @cache = Scrooge::Storage::Cache.new
    @tracker = mock('tracker')
    @tracker.stub!(:signature).and_return('signature')
  end
  
   it "should be able to write a tracker to the framework's cache store" do
     with_rails do
       lambda { @cache.write( @tracker ) }.should change( Rails.cache.storage, :size ).from(0).to(1)
     end
   end
   
   it "should be able to read itself from the framework's cache store" do
     with_rails do
       @cache.write( @tracker )
       @cache.read( @tracker ).should eql( @tracker )
     end
   end
   
end