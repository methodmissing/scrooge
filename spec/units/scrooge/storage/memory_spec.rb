require 'spec/spec_helper'

describe Scrooge::Storage::Memory do
  
  before(:each) do
    @memory = Scrooge::Storage::Memory.new
    @tracker = mock('tracker')
    @tracker.stub!(:signature).and_return('signature')
  end
  
   it "should be able to write a tracker to memory" do
     lambda { @memory.write( @tracker ) }.should change( @memory.storage, :size ).from(0).to(1)
   end
   
   it "should be able to read itself from memory" do
      @memory.write( @tracker )
      @memory.read( @tracker ).should eql( @tracker )
   end
   
end  