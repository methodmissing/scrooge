require "#{File.dirname(__FILE__)}/helper"
 
Scrooge::Test.prepare!
 
class ScroogeTest < ActiveSupport::TestCase
    
  test "should be able to flag applicable records as being scrooged" do
    assert MysqlUser.find(:first).scrooged?
    assert MysqlUser.find_by_sql( "SELECT * FROM mysql.user WHERE User = 'root'" ).first.scrooged?
  end
  
end