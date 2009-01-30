require 'spec/spec_helper'

describe "Scrooge::Framework::Base singleton" do
  
  before(:each) do
    @base = Scrooge::Framework::Base
  end

  it "should be able to track all available frameworks" do
    @base.frameworks.should include( Scrooge::Framework::Rails )
  end
  
  it "should be able to infer the current active framework" do
    lambda{ @base.which_framework? }.should raise_error( Scrooge::Framework::Base::NoSupportedFrameworks )
    with_rails do
      @base.which_framework?().should equal( Scrooge::Framework::Rails )
    end
  end
  
  it "should be able to instantiate the active framework" do
    with_rails do
      @base.instantiate.class.should equal( Scrooge::Framework::Rails )
    end
  end
  
end

describe Scrooge::Framework::Base do
  
  before(:each) do
    @base = Scrooge::Framework::Base.new
  end
  
  it "should be able to yield it's environment" do
    lambda{ @base.environment }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end
  
  it "should be able to yield it's root path" do
    lambda{ @base.root }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end  
  
  it "should be able to yield it's temp path" do
    lambda{ @base.tmp }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end  
  
  it "should be able to yield it's configuration path" do
    lambda{ @base.config }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end
  
  it "should be able to yield it's logger" do
    lambda{ @base.logger }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end    

  it "should be able to read from the framework's cache store" do
    lambda{ @base.read_cache( 'storage' ) }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end    

  it "should be able to write to the framework's cache store" do
    lambda{ @base.write_cache( 'storage', 'payload' ) }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end    
  
  it "should be able to yield a scopes path" do
    with_rails do
      @base.stub!(:config).and_return( CONFIG )
      @base.scopes_path.should match( /config\/scrooge\/scopes/ )  
    end  
  end 
  
  it "should be able to infer all available scopes" do
    with_rails do
      @base.stub!(:config).and_return( CONFIG )
      @base.send( :ensure_scopes_path )
      @signature = Time.now.to_i.to_s
      FileUtils.mkdir_p( File.join( @base.scopes_path, @signature ) )
      @base.scopes.should include( @signature )   
    end
  end
  
  it "should be able to infer the path to a given scope" do
    with_rails do
      @base.stub!(:config).and_return( CONFIG )
      @base.scope_path( '1234567891' ).should match( /scopes\/1234567891/ ) 
    end
  end
  
  it "should be able to interact with the framework's Rack middleware" do
    lambda{ @base.middleware() }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end
  
  it "should be able to install tracking middleware" do
    lambda{ @base.install_tracking_middleware() }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end
  
  it "should be able to install scoping middleware" do
    lambda{ @base.install_scope_middleware( 'tracker' ) }.should raise_error( Scrooge::Framework::Base::NotImplemented )
  end  
  
  
end  