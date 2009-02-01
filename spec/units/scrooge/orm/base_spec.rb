require 'spec/spec_helper'

describe "Scrooge::Orm::Base singleton" do
  
  before(:each) do
    @base = Scrooge::Orm::Base
  end
  
  it "should be able to instantiate a supported ORM from a given ORM signature" do
    @base.instantiate( :active_record ).class.should equal(Scrooge::Orm::ActiveRecord)
  end
  
end

describe Scrooge::Orm::Base do
  
  before(:each) do
    @tracker = mock('tracker')
    @tracker.stub!(:signature).and_return( 'tracker' )
    @base = Scrooge::Orm::Base.new
  end
  
  it "should be able to scope to a given resource tracker" do
    lambda{ @base.scope_to( 'resource_tracker_instance' ) }.should raise_error( Scrooge::Orm::Base::NotImplemented )
  end
  
  it "should be able to generate a name for a given model" do
    lambda{ @base.name( 'model' ) }.should raise_error( Scrooge::Orm::Base::NotImplemented )
  end
  
  it "should be able to generate a table name for a given model" do
    lambda{ @base.table_name( 'model' ) }.should raise_error( Scrooge::Orm::Base::NotImplemented )
  end  
  
  it "should be able to generate a per resource scope method" do
    @base.resource_scope_method( @tracker ).should eql( :scope_to_tracker )
  end
  
  it "should be able to determine if a given scope method has already been defined" do
    @base.resource_scope_method?( @tracker, @tracker.class ).should equal( false )
  end
  
  it "should be able to infer the current trackable resource" do
    Thread.current[:scrooge_resource] = 'resource'
    @base.resource().should eql( 'resource' )
    Thread.current[:scrooge_resource] = nil
  end
  
  it "should be able to determine if it's within the context of a trackable resource" do
    @base.resource?().should eql( false )
  end
  
  it "should be able to determine if it should track attribute access" do
    @base.track?().should equal( false )
  end
  
end  