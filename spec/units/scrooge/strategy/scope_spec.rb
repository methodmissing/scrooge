require 'spec/spec_helper'

describe Scrooge::Strategy::Scope do
  
  before(:each) do
    @scope = Scrooge::Strategy::Scope.new
    @controller = Scrooge::Strategy::Controller.new( @scope )
    Scrooge::Base.profile.framework.stub!(:install_scope_middleware).and_return('installed')
  end
  
  it "should be able to execute a given strategy" do
    lambda{ @controller.run!().value }.should raise_error( NameError )
  end
  
end