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

  it "should initialize with a buffer flushed at timestamp" do
    @base.buffer_flushed_at.class.should equal( Bignum )
  end

  it "should initialize with an empty storage buffer" do
    @base.storage_buffer.should eql( {} )
  end

  it "should be able to determine if it should buffer storage" do
    @base.buffer?().should eql( false )
  end

  it "should be able to read from the storage backend" do
    lambda{ @base.read( @tracker ) }.should raise_error( Scrooge::Storage::Base::NotImplemented )
  end
  
  it "should be able to write to the storage backend" do
    lambda{ @base.write( @tracker ) }.should raise_error( Scrooge::Storage::Base::NotImplemented )
  end    
  
  it "should be able to determine if it should flush it's buffer" do
    @base.flush_buffer?().should eql( false )
    @base.stub!(:buffer?).and_return(true)
    @base.flush_buffer?().should eql( false )
    @base.profile.stub!(:buffer_threshold).and_return(-10)
    @base.flush_buffer?().should eql( true )
  end
  
  it "should be able to buffer a tracker" do
    lambda { @base.buffer( @tracker ) }.should change( @base.storage_buffer, :size ).from(0).to(1)
    @base.storage_buffer['signature'].should eql( @tracker )
  end
  
  it "should be able to yield a namespaced storage key" do
    @base.expand_key( "signature" ).should eql( "scrooge_storage/signature" )
  end
  
  it "should be able to flush all storage buffers" do
    @base.buffer( @tracker )
    @base.stub!(:write).and_return(@tracker)
    lambda { @base.flush! }.should change( @base.storage_buffer, :size ).from(1).to(0)
    @base.storage_buffer.should be_empty
  end
  
  it "should be able to commit a tracker to commit a tracker to storage and register it with centralized lookup" do
    @base.stub!(:unbuffered_read).and_return(nil)  
    @base.stub!(:unbuffered_write).and_return(@tracker)      
    @base.stub!(:write).and_return(@tracker)
    ( @base << @tracker ).should eql( @tracker )
  end
  
end  