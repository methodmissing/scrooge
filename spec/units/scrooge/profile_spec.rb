require 'spec/spec_helper'

describe "Scrooge::Profile singleton" do
  
  before(:each) do
    @profile = Scrooge::Profile
  end
  
  it "should be able to instantiate it self from a given config path and environment" do
    @profile.setup( File.join( FIXTURES, 'config', 'scrooge.yml' ), :production ).class.should equal( Scrooge::Profile )
    @profile.setup( File.join( FIXTURES, 'config', 'scrooge.yml' ), :test ).options['orm'].should == 'active_record'
  end
  
end

describe "Scrooge::Profile instance" do
 
  before(:each) do
    @profile = Scrooge::Profile.setup( File.join( FIXTURES, 'config', 'scrooge.yml' ), :production )
  end  
  
  it "should be able to determine if a warmup is desireable" do
    @profile.should be_warmed_up
  end
  
  it "should be able to determine if storage should be buffered" do
    @profile.should be_buffered
  end  
  
  it "should return a valid warmup threshold" do
    @profile.warmup_threshold.should eql(300)
  end
  
  it "should return a valid buffer threshold" do
    @profile.buffer_threshold.should eql(60)
  end  
  
  it "should return a valid ORM instance" do
    @profile.orm.class.should equal( Scrooge::Orm::ActiveRecord )
  end
  
  it "should return a valid storage instance" do
    @profile.storage.class.should equal( Scrooge::Storage::Memory )
  end
  
  it "should return a valid framework instance" do
    with_rails do
      @profile.framework.class.should equal( Scrooge::Framework::Rails )
    end
  end
    
  it "should return a valid tracker instance" do
    @profile.tracker.class.should equal( Scrooge::Tracker::App )
  end    
   
  it "should be able to determine if the active profile should track or scope" do
    @profile.track?().should equal( false )
    @profile.scope?().should equal( true )
  end 
  
  it "should be able to infer the current scope" do
    @profile.scope_to.should eql( 1234567891 )
  end
    
end