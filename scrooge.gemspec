# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{scrooge}
  s.version = "2.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lourens Naud\303\251", "Stephen Sykes"]
  s.date = %q{2009-03-13}
  s.description = %q{An ActiveRecord attribute tracker to ensure production Ruby applications only fetch the database content needed to minimize wire traffic and reduce conversion overheads to native Ruby types.}
  s.email = %q{lourens@methodmissing.com or sds@switchstep.com}
  s.files = ["Rakefile", "README", "README.textile", "VERSION.yml", "lib/attributes_proxy.rb", "lib/scrooge.rb", "test/helper.rb", "test/models", "test/models/mysql_user.rb", "test/scrooge_test.rb", "test/setup.rb", "rails/init.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/methodmissing/scrooge}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Scrooge - Fetch exactly what you need}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
