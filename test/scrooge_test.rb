require "#{File.dirname(__FILE__)}/helper"

Scrooge::Test.prepare!

class ScroogeTest < ActiveRecord::TestCase

  teardown do
    MysqlUser.scrooge_flush_callsites!
  end

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
  
  test "should be able to track callsites" do
    assert_difference 'MysqlUser.scrooge_callsites.size' do
      MysqlUser.find(:first)
    end
  end
  
  test "should be able to retrieve a callsite form a given signature" do
    assert MysqlUser.find(:first).scrooged?
    assert_instance_of Scrooge::Callsite, MysqlUser.scrooge_callsite( first_callsite )
  end

  test "should not flag records via Model.find with a custom :select requirement as scrooged" do
    assert !MysqlUser.find(:first, :select => 'user.Password' ).scrooged?
  end
  
  test "should be able to augment an existing callsite with attributes" do
    MysqlUser.find(:first)
    MysqlUser.scrooge_seen_column!( first_callsite, 'Password' )
    assert MysqlUser.scrooge_callsite( first_callsite ).columns.include?( 'Password' )
  end
  
  test "should be able to generate a SQL select snippet from a given set" do
    assert_equal MysqlUser.scrooge_select_sql( SimpleSet['Password','User','Host'] ), "`user`.User,`user`.Password,`user`.Host"
  end
 
  test "should be able to augment an existing callsite when attributes is referenced that we haven't seen yet" do
    user = MysqlUser.find(:first)
    MysqlUser.expects(:scrooge_seen_column!).times(2)
    user.Password
    user.Host
  end
  
  test "should not augment the callsite with known columns" do
    user = MysqlUser.find(:first)
    MysqlUser.expects(:augment_scrooge_callsite!).never
    user.User
  end
  
  test "should only fire after_initialize once" do
    # should not raise ActiveRecord::MissingAttributeError
    [:max_connections, :max_user_connections].each {|f| MysqlUser.find(:first).read_attribute(f)}
  end
  
  test "should make 3 queries to fetch same item twice due to reload and remembering" do
    assert_queries(3) {2.times {MysqlUser.find(:first).max_connections}}
  end
  
  def first_callsite
    MysqlUser.scrooge_callsites.to_a.flatten.first
  end
  
end