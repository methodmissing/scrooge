require 'spec/spec_helper'

describe Scrooge::Strategy::TrackThenScope do
  
  before(:each) do
    Scrooge::Base.profile.stub!(:warmup).and_return( 1 )    
    @track_then_scope = Scrooge::Strategy::TrackThenScope.new
    @controller = Scrooge::Strategy::Controller.new( @track_then_scope )
    Scrooge::Base.profile.framework.stub!(:install_tracking_middleware).and_return('installed')
    Scrooge::Base.profile.framework.stub!(:uninstall_tracking_middleware).and_return('installed')    
    Scrooge::Base.profile.framework.stub!(:install_scope_middleware).and_return('installed')
  end
  
  it "should be able to execute a given strategy" do
    Scrooge::Base.profile.stub!(:synchronize!).and_return([])
    Scrooge::Base.profile.stub!(:aggregate!).and_return([])
    with_rails do
      @controller.run!().value.should include( 'installed' )
    end
  end
  
end