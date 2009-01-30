require 'spec/spec_helper'

describe Scrooge::Storage::FileSystem do
  
  before(:each) do
    @file_system = Scrooge::Storage::FileSystem.new
    @tracker = mock('tracker')
    @tracker.stub!(:signature).and_return('signature')
    @framework = mock('framework')
    @framework.stub!(:tmp).and_return( TMP )
    @framework.stub!(:logger).and_return Logger.new( STDOUT )
    @file_system.profile.stub!(:framework).and_return( @framework )
    @file_system.stub!(:buffer?).and_return(false)
    Marshal.stub!(:dump).and_return('tracker')
    Marshal.stub!(:load).and_return('tracker')
  end
  
  it "should be able to compute a tracker directory path" do
    @file_system.tracker_path( @tracker ).should match( /tmp\/signature/ )
  end
  
  it "should be able to compute a tracker file path" do
    @file_system.tracker_file( @tracker ).should match( /tmp\/signature\/scrooge/ )
  end  
  
  it "should be able to write a tracker to disk" do    
    @file_system.write( @tracker )
    File.exist?( @file_system.tracker_file( @tracker ) ).should equal( true )
  end
  
  it "should be able to read a tracker from disk" do
    @file_system.write( @tracker )
    @file_system.read( @tracker ).should eql( 'tracker' )
  end
  
end  