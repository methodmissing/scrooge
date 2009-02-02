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