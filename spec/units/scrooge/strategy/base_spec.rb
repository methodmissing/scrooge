require 'spec/spec_helper'

describe 'Scrooge::Strategy::Base singleton' do
 
  after(:each) do
    Scrooge::Strategy::Base.flush!
  end
  
  it "should be able to determine if it has any stages" do
    Scrooge::Strategy::Base.stages?().should equal( false )
    Scrooge::Strategy::Base.stage( :stage ) do
      'payload'
    end
    Scrooge::Strategy::Base.stages?().should equal( true )
  end
  
  it "should be able to yield all it's defined stages" do
    Scrooge::Strategy::Base.stages.should eql( [] )
  end
  
  it "should be able to register one or more execution stages" do
    lambda do 
      Scrooge::Strategy::Base.stage( :stage ) do
        'payload'
      end
    end.should change( Scrooge::Strategy::Base.stages, :size ).from(0).to(1)
  end
  
  it "should require at least one defined stage" do
    lambda{ @base.scope_to( Scrooge::Strategy::Base.new ) }.should raise_error( Scrooge::Strategy::Base::NoStages )
  end
  
end  

describe Scrooge::Strategy::Base do
  
  before(:each) do
    Scrooge::Strategy::Base.stage( :stage ) do
      'payload'
    end
    @base = Scrooge::Strategy::Base.new
  end
  
  after(:each) do
    Scrooge::Strategy::Base.flush!
  end  
  
  it "should be able to infer all defined stages" do
    @base.stages.first.class.should eql( Scrooge::Strategy::Stage )
  end
  
  it "should be able to execute itself" do
    @base.execute!().class.should == Thread
  end
  
  it "should provide access to it's controller Thread" do
    @base.execute!
    @base.thread.class.should == Thread
  end
  
end