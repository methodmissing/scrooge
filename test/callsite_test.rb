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

  test "should be inspectable" do
    @callsite.association! :mysql_user, 123456
    @callsite.column! :db
    assert_equal @callsite.inspect, "<#MysqlTablePrivilege :select => '`tables_priv`.db', :include => [:mysql_user]>"
  end
  
  test "should flag a column as seen" do
    assert_difference '@callsite.columns.size' do
      @callsite.column! :Db
    end
  end
  
  test "should flag only preloadable associations as seen" do
    assert_no_difference '@callsite.associations.to_preload.size' do
      @callsite.association! :undefined, 123456
    end
    assert_difference '@callsite.associations.to_preload.size', 2 do
      @callsite.association! :column_privilege, 123456
      @callsite.association! :mysql_user, 123456
    end
  end

end  