require 'spec/spec_helper'

describe Scrooge::Strategy::Base do
  
  before(:each) do
    Scrooge::Strategy::Base.stage( :stage ) do
      'payload'
    end
    @base = Scrooge::Strategy::Base.new
    @controller = Scrooge::Strategy::Controller.new( @base )
  end
  
  after(:each) do
    Scrooge::Strategy::Base.flush!
  end
  
  it "should be able to execute a given strategy" do
    @controller.run!().should include( 'payload' )
  end
  
end  