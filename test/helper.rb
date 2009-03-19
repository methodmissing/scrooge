require File.join( File.dirname(__FILE__), 'setup' )
require 'rubygems'
require 'mocha'
require 'active_support/test_case'

module Scrooge
  class Test
    
    MODELS_DIR = "#{File.dirname(__FILE__)}/models".freeze
    
    class << self
      
      def prepare!
        require 'test/unit'
        connect!
        require_models()
      end
            
      def setup!
        setup_constants!
        setup_config!
      end
        
      def connection
        File.join( AR_TEST_SUITE, 'connections', 'native_mysql' )
      end

      def active_record_test_files
        (files ||= [] ) << glob( "#{AR_TEST_SUITE}/cases/**/*_test.rb" )
        files.sort
      end

      def test_files
        glob( "#{File.dirname(__FILE__)}/**/*_test.rb" )
      end

      private

      def connect!
        ::ActiveRecord::Base.establish_connection( :adapter  => 'mysql',
                                                   :username => 'root',
                                                   :database => 'mysql',
                                                   :pool => 1 )
      end

      def require_models
        Dir.entries( MODELS_DIR ).grep(/.rb/).each do |model|
          require_model( model )
        end  
      end  

      def require_model( model )
        require "#{MODELS_DIR}/#{model}"
      end

      def setup_constants!
        set_constant( 'MYSQL_DB_USER' ){ 'rails' }
        set_constant( 'AR_TEST_SUITE' ) do 
          find_active_record_test_suite()
        end
      end
      
      def setup_config!
        unless Object.const_defined?( 'MIGRATIONS_ROOT' )
          require "#{::AR_TEST_SUITE}/config"
        end
      end

      def set_constant( constant )
        Object.const_set(constant, yield ) unless Object.const_defined?( constant )
      end
 
      def find_active_record_test_suite
        ts = ($:).grep( /activerecord/ ).last.split('/')
        ts.pop
        ts << 'test'
        ts.join('/')
      end

      def glob( pattern )
        Dir.glob( pattern )
      end        
            
    end
  end
end

Scrooge::Test.setup!