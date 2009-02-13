require 'spec/spec_helper'

describe "Scrooge::Profile singleton" do
  
  before(:each) do
    @profile = Scrooge::Profile
  end
  
  it "should be able to instantiate it self from a given config path and environment" do
    @profile.setup( File.join( FIXTURES, 'config', 'scrooge.yml' ), :production ).class.should equal( Scrooge::Profile )
    @profile.setup( File.join( FIXTURES, 'config', 'scrooge.yml' ), :test ).options['orm'].should equal( :active_record )
  end
  
end

describe "Scrooge::Profile instance" do
 
  before(:each) do
    @profile = Scrooge::Profile.setup( File.join( FIXTURES, 'config', 'scrooge.yml' ), :production )
    @profile.framework.stub!(:scopes).and_return( %w(1234567891) )
    @profile.options = { 'scope' => '1234567891'}
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
  
  it "should be able to infer the current scope" do
    @profile.scope.should eql( "1234567891" )
  end
    
  it "should be able to determine if it's enabled" do
    @profile.enabled?().should eql( false )  
  end  
    
  it "should be able to determine if it should raise on missing attributes" do    
    @profile.raise_on_missing_attribute?().should equal( false )  
  end  
    
  it "should be able to fallback to scope from the environment if none given" do
    @profile.framework.stub!(:scopes).and_return( [] )
    ENV['scope'] = 'scope_from_env'
    @profile.send(:configure!)
    @profile.scope.should eql( 'scope_from_env' )   
  end  
    
  it "should be able to yield a stategy instance" do
    @profile.strategy.class.should == Scrooge::Strategy::Track 
  end  
    
end