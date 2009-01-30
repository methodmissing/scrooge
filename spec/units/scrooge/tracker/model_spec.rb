require 'spec/spec_helper'

describe Scrooge::Tracker::Model do
  
  before(:each) do
    @model = Scrooge::Tracker::Model.new( 'Post' )
    @model.stub!(:name).and_return( 'Product' )
    @model.stub!(:table_name).and_return( 'products' )    
  end
  
  it "should initialize with an empty set of attributes" do
    @model.attributes.should eql( Set.new )
  end
  
  it "should be able to accept attributes" do
    lambda { @model << :name }.should change( @model.attributes, :size ).from(0).to(1)
  end
  
  it "should be able to dump itself to a serializeable representation" do
    @model << [:name, :description, :price]
    @model.marshal_dump().should eql( { "Product" => [:price, :description, :name] } )
  end
  
  it "should be able to restore itself from a serialized representation" do
    @model << [:name, :description, :price]
    lambda{ @model.marshal_load( { "Product" => [:price] } ) }.should change( @model.attributes, :size ).from(3).to(1)
  end
  
  it "should be able to render a attribute selection SQL snippet from it's referenced attributes" do
    @model << [:name, :description, :price]
    @model.to_sql().should eql( "products.price, products.description, products.name" )
  end
  
  specify "should be able to compare itself to other model trackers" do
    @model << [:name, :description, :price]
    @model.should eql( @model )
  end
  
end