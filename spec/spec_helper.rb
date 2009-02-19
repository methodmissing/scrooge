$:.unshift File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'fileutils'
require 'logger'
require 'stringio'
require 'lib/scrooge'
require 'spec/helpers/framework/rails/cache'

#ActiveRecord::Base.logger = Logger.new(StringIO.new)

Spec::Runner.configure do |config|
  
  def self.set_constant( const, value )
    eval( "Kernel.const_set :#{const.to_s}, #{value.inspect} unless defined?( #{const.to_s} )" )
  end
  
  set_constant( :FIXTURES, "#{Dir.pwd}/spec/fixtures" )
  set_constant( :TMP, "#{Dir.pwd}/spec/tmp" )
  set_constant( :CONFIG, "#{Dir.pwd}/spec/config" )
  
  config.before :all do
    [TMP, CONFIG].each do |dir|
      FileUtils.mkdir_p dir
    end
  end
  
  config.before :each do
  end
  
  config.after :each do
  end    
  
  config.after :all do
    [TMP, CONFIG].each do |dir|
      FileUtils.rm_r( dir ) rescue nil
    end
  end
  
  def with_rails
    begin
      Kernel.const_set :RAILS_ROOT, "#{Dir.pwd}/spec" unless defined?(RAILS_ROOT)
      Kernel.const_set :Rails, Class.new unless defined?(Rails)
      Kernel.const_set :RAILS_ENV, "test" unless defined?(RAILS_ENV)
      ::Rails.stub!(:cache).and_return( Spec::Helpers::Framework::Rails::Cache.new )
      ::Rails.stub!(:root).and_return( RAILS_ROOT )
      yield
    ensure
      [:RAILS_ROOT, :RAILS_ENV, :Rails].each do |const|  
        Kernel.send( :remove_const, const )
      end
    end
  end
  
end