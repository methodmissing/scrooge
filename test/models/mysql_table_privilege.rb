class MysqlTablePrivilege < ActiveRecord::Base
  set_table_name 'tables_priv'
  set_primary_key nil 
  
  belongs_to :mysql_user, :class_name => 'MysqlUser', :foreign_key => 'User'
  belongs_to :column_privilege, :class_name => 'MysqlColumnPrivilege', :foreign_key => 'Column_priv' 
  
end