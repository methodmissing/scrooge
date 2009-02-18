require 'spec/spec_helper'

describe Scrooge::Tracker::Resource do
  
  before(:each) do
    @resource = Scrooge::Tracker::Resource.new do |resource|
                  resource.controller = 'products'
                  resource.action = 'show'
                  resource.method = :get
                  resource.format = :html
                  resource.is_public = true
                end
    @model = Scrooge::Tracker::Model.new( 'Class' )
    @model.stub!(:name).and_return( 'Product' )
    @model.stub!(:table_name).and_return( 'products' )  
    @model.stub!(:primary_key).and_return( 'id' )      
    @other_resource = Scrooge::Tracker::Resource.new do |resource|
                        resource.controller = 'categories'
                        resource.action = 'show'
                        resource.method = :get
                        resource.format = :html
                        resource.is_public = true
                      end
  end
  
  it "should be able to determine if any models has been tracked" do
    @resource.any?().should equal( false )
  end
  
  it "should be able to determine if it's a public resource" do
    @resource.public?().should equal( true )
  end
  
  it "should be able to determine if it's a private resource" do
    @resource.private?().should equal( false )
  end
    
  it "should initialize with an empty set of models" do
    @resource.models.should eql( Set.new )
  end
  
  it "should be able to accept models" do
    lambda { @resource << @model }.should change( @resource.models, :size ).from(0).to(1)
  end
  
  it "should be able to wrap model objects" do
    @resource << 'Model'
    @resource.models.all?{|m| m.is_a?( Scrooge::Tracker::Model ) }.should equal( true )
  end
  
  it "should be able to log an attribute access for a given model" do
    @resource << ['Post', :title]
    @resource.models.first.attributes.should eql( Set[:title] )
  end
  
  it "should be able to determine if it's trackable" do
    @resource.trackable?().should equal( true )
    @resource.stub!(:method).and_return( :put )
    @resource.trackable?().should equal( false )
  end
  
  it "should be able to generate a lookup signature" do
    @resource.signature().should eql( "products_show_get_public" )
  end
  
  it "should be able to dump itself to a serializeable representation" do
    @resource.marshal_dump().should eql( { "products_show_get_public" => { :models => [],
                                                                      :method => :get,   
                                                                      :format => :html,
                                                                      :action => "show",   
                                                                      :controller => "products",
                                                                      :is_public => true} } )
  end
  
  it "should be able to restore itself from a serialized representation" do
    Marshal.load( Marshal.dump( @resource ) ).should eql( @resource )
  end  
  
  it "should be able to compare itself to other resource trackers" do
    @resource.should eql( @resource )
  end
  
  it "should be able to setup Rack middleware" do
    @resource.profile.orm.stub!(:resource_scope_method).and_return(:scoped_to_resource_method)
    @resource << @model
    @resource.middleware().class.should equal( Array )
    @resource.middleware().first.class.should equal( Class )
    @resource.middleware().first.inspect.should match( /Middleware/ )
    @resource.middleware().first.inspect.should match( /Product/ )
    @resource.middleware().first.new( @model ).should respond_to( :call )
  end
  
  it "should implemented a custom Object#inspect" do
    @resource << @model
    @resource.inspect().should match( /GET/ )
    @resource.inspect().should match( /products/ )
    @resource.inspect().should match( /Product/ )
  end  
  
  it "should be able to find a given model" do
    @resource << @model
    other_model = mock('model')
    other_model.stub!(:name).and_return('Product')
    @resource.model( other_model ).should == @model
  end
  
  it "should be able to merge itself with another resource" do
    @other_resource << @model
    @resource.merge( @other_resource )
    @resource.models.to_a.should eql( [@model] )
    @resource.models.should_not_receive(:merge)
    @resource.merge( nil )
  end
  
end