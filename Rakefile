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

namespace :scrooge do
  
  desc "Copies over the example scrooge.yml file to the host framework's configuration directory"
  task :setup do
    Scrooge::Base.setup!
  end  

  desc "List all available Scrooge scopes"
  task :list do
    Scrooge::Profile.framework.scopes.each do |scope|
      puts "- #{scope}"
    end
  end

  desc "Dumps Resources and Models for a given scope to a human friendly format.Assumes ENV['scope'] is set."
  task :inspect do
    begin
      Scrooge::Profile.framework.from_scope!( ENV['scope'] )
      puts Scrooge::Profile.tracker.inspect
    rescue Scrooge::Framework::InvalidScopeSignature
      puts "Please set ENV['scope'] to the scope you'd like to inspect."
    end    
  end

end  