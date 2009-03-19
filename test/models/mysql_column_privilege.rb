class MysqlColumnPrivilege < ActiveRecord::Base
  set_table_name 'columns_priv'
  set_primary_key nil 
  
  belongs_to :mysql_user, :class_name => 'MysqlUser', :foreign_key => 'User'
  
end