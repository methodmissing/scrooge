require 'spec/spec_helper'

describe Scrooge::Framework::Rails do
  
  before(:each) do
    @framework = Scrooge::Framework::Rails.new
  end

  it "should be able to yield it's current environment" do
    with_rails do
      @framework.environment.should eql( 'test' )
    end
  end

  it "should be able to yield a logger" do
    with_rails do
      ::Rails.stub!(:logger).and_return('')
      ( @framework.logger << 'entry' ).should eql( 'entry' )
    end
  end
  
  it "should be able to yield it's configuration" do
    with_rails do
      @framework.config.should match( /scrooge\/spec\/config/ )
    end
  end  
  
  it "should be able to yield it's root path" do
    with_rails do
      @framework.root.should match( /scrooge\/spec/ )
    end
  end  
  
  it "should be able to yield it's tmp path" do
    with_rails do
      @framework.tmp.should match( /scrooge\/spec\/tmp/ )
    end
  end  
  
end