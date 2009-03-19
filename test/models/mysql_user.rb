class MysqlUser < ActiveRecord::Base  
  set_table_name 'user'
  set_primary_key 'User'
  
  has_many :table_privileges, :class_name => 'MysqlTablePrivilege', :foreign_key => 'User'
  has_many :column_privileges, :class_name => 'MysqlColumnPrivilege', :foreign_key => 'User'
  belongs_to :host, :class_name => 'MysqlHost', :foreign_key => 'Host'
  
  def after_initialize
    max_connections if @attributes.has_key?("max_user_connections")
  end
  
end