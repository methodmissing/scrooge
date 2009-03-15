class MysqlUser < ActiveRecord::Base  
  set_table_name 'user'
  set_primary_key 'User'
  
  def after_initialize
    max_connections
  end
end