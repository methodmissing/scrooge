$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'scrooge'

Scrooge::Framework::Rails

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
      Scrooge::Base.profile.scope_to_signature!( ENV['scope'] )
      puts Scrooge::Base.profile.tracker.inspect
    rescue Scrooge::Framework::Base::InvalidScopeSignature
      puts "Please set ENV['scope'] to the scope you'd like to inspect."
    end    
  end

end