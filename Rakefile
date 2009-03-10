require 'rake'
require 'rake/testtask'
require 'test/helper'

task :default => [:test_with_active_record, :test_scrooge]

Rake::TestTask.new( :test_with_active_record ) { |t|
  t.libs << AR_TEST_SUITE << Scrooge::Test.connection() 
  #t.test_files = ["/Users/lourens/projects/rails/activerecord/test/cases/validations_test.rb"]
  t.test_files = Scrooge::Test.active_record_test_files()
  t.ruby_opts = ["-r #{File.join( File.dirname(__FILE__), 'test', 'setup' )}"]
  t.verbose = true
}

Rake::TestTask.new( :test_scrooge ) { |t|
  t.libs << 'lib'
  t.test_files = Scrooge::Test.test_files()
  t.verbose = true
}

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "scrooge"
    s.summary = "Scrooge - Fetch exactly what you need"
    s.email = "lourens@methodmissing.com or sds@switchstep.com"
    s.homepage = "http://github.com/methodmissing/scrooge"
    s.description = "An ActiveRecord attribute tracker to ensure production
    Ruby applications only fetch the database content needed to minimize wire traffic
    and reduce conversion overheads to native Ruby types."
    s.authors = ["Lourens Naudé", "Stephen Sykes"]
    s.files = FileList["[A-Z]*", "{lib,test,rails,tasks}/**/*"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end