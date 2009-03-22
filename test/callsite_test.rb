require "#{File.dirname(__FILE__)}/helper"
 
Scrooge::Test.prepare!

class CallsiteTest < ActiveSupport::TestCase
  
  def setup
    @callsite = Scrooge::Callsite.new( MysqlTablePrivilege, 123456 )
  end
  
  test "should initialize with a default set of columns" do
    assert @callsite.columns.empty?
    assert_equal Scrooge::Callsite.new( MysqlUser, 123456 ).columns, Set["User"]
    Scrooge::Callsite.any_instance.stubs(:inheritable?).returns(true)
    Scrooge::Callsite.any_instance.stubs(:inheritance_column).returns("inheritance")
    assert_equal Scrooge::Callsite.new( MysqlUser, 123456 ).columns, Set["User","inheritance"]
  end
  
  test "should be able to return all augmented columns" do
    assert_equal @callsite.augmented_columns, Set.new
    @callsite.column! :Db
    assert_equal @callsite.augmented_columns, Set[:Db] 
  end
  
  test "should be able to determine if any columns has been augmented" do
    assert !@callsite.augmented_columns?
    @callsite.column! :Db
    assert @callsite.augmented_columns?
  end
  
  test "should be inspectable" do
    @callsite.association! :mysql_user
    @callsite.column! :db
    assert_equal @callsite.inspect, "<#MysqlTablePrivilege :select => '`tables_priv`.db', :include => [:mysql_user]>"
  end
  
  test "should flag a column as seen" do
    assert_difference '@callsite.columns.size' do
      @callsite.column! :Db
    end
  end
  
  test "should flag only preloadable associations as seen" do
    assert_no_difference '@callsite.associations.size' do
      @callsite.association! :undefined
    end
    assert_difference '@callsite.associations.size', 2 do
      @callsite.association! :column_privilege
      @callsite.association! :mysql_user
    end
  end
  
  test "should be able to overload given association preload options" do
    assert_equal @callsite.preload( { :nested => :include } ), { :nested => :include }
    assert_equal @callsite.preload( [:column_privilege] ), [:column_privilege]
    @callsite.association! :column_privilege
    @callsite.association! :mysql_user
    assert_equal @callsite.preload( nil ).sort_by(&:to_s), [:column_privilege, :mysql_user].sort_by(&:to_s)
  end
  
  
end  