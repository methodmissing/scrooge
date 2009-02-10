begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end

require 'spec/rake/spectask'

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../'
$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

require 'scrooge'

desc "Run the specs under spec"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts << "-c"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "scrooge"
    s.summary = "Scrooge - Fetch exactly what you need"
    s.email = "lourens@methodmissing.com"
    s.homepage = "http://github.com/methodmissing/scrooge"
    s.description = "A Framework and ORM agnostic Model / record attribute tracker to ensure production
    Ruby applications only fetch the database content needed to minimize wire traffic
    and reduce conversion overheads to native Ruby types."
    s.authors = ["Lourens Naudé"]
    s.files = FileList["[A-Z]*", "{lib,spec,rails,assets,tasks}/**/*"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end