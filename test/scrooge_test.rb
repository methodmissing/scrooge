require "#{File.dirname(__FILE__)}/helper"
 
Scrooge::Test.prepare!
 
class ScroogeTest < ActiveSupport::TestCase
    
  test "should not attempt to optimize models without a defined primary key" do
    MysqlUser.stubs(:primary_key).returns('undefined')
    MysqlUser.expects(:find_by_sql_with_scrooge).never
    MysqlUser.find(:first)  
  end  
    
  test "should not optimize any SQL other than result retrieval" do
    MysqlUser.expects(:find_by_sql_with_scrooge).never 
    MysqlUser.find_by_sql("SHOW fields from mysql.user")
  end  
  
  test "should not optimize inner joins" do
    MysqlUser.expects(:find_by_sql_with_scrooge).never 
    MysqlUser.find_by_sql("SELECT * FROM columns_priv INNER JOIN user ON columns_priv.User = user.User")
  end
    
  test "should be able to flag applicable records as being scrooged" do
    assert MysqlUser.find(:first).scrooged?
    assert MysqlUser.find_by_sql( "SELECT * FROM mysql.user WHERE User = 'root'" ).first.scrooged?
  end
  
end