require 'spec/spec_helper'

describe Scrooge::Tracker::App do
  
  before(:each) do
    @app = Scrooge::Tracker::App.new
    @resource = Scrooge::Tracker::Resource.new do |resource|
                  resource.controller = 'products'
                  resource.action = 'show'
                  resource.method = :get
                  resource.format = :html
                end
  end
  
  it "should be able to determine if any resources has been tracked" do
    @app.any?().should equal( false )
  end
  
  it "should initialize with an empty set of resources" do
    @app.resources.should eql( Set.new )
  end
  
  it "should be able to accept resources" do
    lambda { @app << 'a_resource' }.should change( @app.resources, :size ).from(0).to(1)
  end
  
  it "should be able to dump itself to a serializeable representation" do
    @app << @resource
    with_rails do
      @app.marshal_dump().should eql( [ { "products_show_get" => { :method => :get,
                                                                   :models => [],
                                                                   :format => :html,
                                                                   :action => "show",
                                                                   :controller => "products" } } ] )
    end
  end

  it "should be able to restore itself from a serialized representation" do
    @app << @resource
    with_rails do
      Marshal.load( Marshal.dump( @app ) ).should eql( @app )
    end  
  end

  it "should be able to compare itself to other app trackers" do
    with_rails do
      @app.should eql( @app )
    end  
  end
  
  it "should implemented a custom Object#inspect" do  
    @app << @resource
    @app.inspect().should match( /GET/ )  
    @app.inspect().should match( /products/ )
  end
  
end