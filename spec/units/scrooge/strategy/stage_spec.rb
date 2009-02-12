require 'spec/spec_helper'

describe Scrooge::Strategy::Stage do
  
  before(:each) do
    @stage = Scrooge::Strategy::Stage.new( :test, :for => 0.5 ) do
               'payload'
             end
  end
  
  it "should be able to determine if it's executeable" do
    @stage.executeable?().should equal( true )
  end
  
  it "should be able to determine if it's initialized" do
    @stage.initialized?().should equal( true )
  end
  
  it "should be able to determine if it's in execution" do
    @stage.running?().should equal( false )
    @stage.execute!
    @stage.running?().should equal( false )
  end
  
  it "should be able to execute itself" do
    @stage.execute!().should eql( "payload" )
  end
  
  it "should be able to determine if it's terminated" do
    @stage.terminated?().should equal( false )
    @stage.execute!
    @stage.terminated?().should equal( true )
  end
  
end