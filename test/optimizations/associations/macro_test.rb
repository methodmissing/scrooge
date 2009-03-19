require "#{File.dirname(__FILE__)}/../../helper"
 
Scrooge::Test.prepare!

class OptimizationsAssociationsMacroTest < ActiveSupport::TestCase
  
  test "should flag a record as being scrooged when found through a supported SQL query" do
    assert MysqlUser.find(:first).scrooged?
  end

  test "should be able to flag any associations instantiated from a record" do
    @user = MysqlUser.find(:first)
    @user.host
    assert_equal MysqlUser.scrooge_callsite( @user.callsite_signature ).associations, Set[:host]
  end

  test "should only flag preloadable associations" do
    Scrooge::Callsite.any_instance.expects(:association!).once
    @user = MysqlUser.find(:first)
    @user.table_privileges
    assert_equal MysqlUser.scrooge_callsite( @user.callsite_signature ).associations, Set.new
  end
  
  test "should be able to identify all preloadable associations for a given Model" do
    assert_equal MysqlUser.preloadable_associations, [:host]
    assert_equal MysqlHost.preloadable_associations, []
    assert_equal MysqlColumnPrivilege.preloadable_associations, [:mysql_user]
    assert_equal MysqlTablePrivilege.preloadable_associations, [:mysql_user, :column_privilege]
  end
  
end  