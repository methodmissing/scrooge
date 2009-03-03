# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{scrooge}
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lourens Naud\303\251"]
  s.date = %q{2009-03-03}
  s.description = %q{A Framework and ORM agnostic Model / record attribute tracker to ensure production Ruby applications only fetch the database content needed to minimize wire traffic and reduce conversion overheads to native Ruby types.}
  s.email = %q{lourens@methodmissing.com}
  s.files = ["Rakefile", "README", "README.textile", "VERSION.yml", "lib/scrooge", "lib/scrooge/core", "lib/scrooge/core/string.rb", "lib/scrooge/core/symbol.rb", "lib/scrooge/core/thread.rb", "lib/scrooge/framework", "lib/scrooge/framework/base.rb", "lib/scrooge/framework/rails.rb", "lib/scrooge/middleware", "lib/scrooge/middleware/tracker.rb", "lib/scrooge/orm", "lib/scrooge/orm/active_record.rb", "lib/scrooge/orm/base.rb", "lib/scrooge/profile.rb", "lib/scrooge/storage", "lib/scrooge/storage/base.rb", "lib/scrooge/storage/memory.rb", "lib/scrooge/strategy", "lib/scrooge/strategy/base.rb", "lib/scrooge/strategy/controller.rb", "lib/scrooge/strategy/scope.rb", "lib/scrooge/strategy/stage.rb", "lib/scrooge/strategy/track.rb", "lib/scrooge/strategy/track_then_scope.rb", "lib/scrooge/tracker", "lib/scrooge/tracker/app.rb", "lib/scrooge/tracker/base.rb", "lib/scrooge/tracker/model.rb", "lib/scrooge/tracker/resource.rb", "lib/scrooge.rb", "spec/fixtures", "spec/fixtures/config", "spec/fixtures/config/scrooge", "spec/fixtures/config/scrooge/scopes", "spec/fixtures/config/scrooge/scopes/1234567891", "spec/fixtures/config/scrooge/scopes/1234567891/scope.yml", "spec/fixtures/config/scrooge.yml", "spec/helpers", "spec/helpers/framework", "spec/helpers/framework/rails", "spec/helpers/framework/rails/cache.rb", "spec/spec_helper.rb", "spec/units", "spec/units/scrooge", "spec/units/scrooge/core", "spec/units/scrooge/core/string_spec.rb", "spec/units/scrooge/core/symbol_spec.rb", "spec/units/scrooge/core/thread_spec.rb", "spec/units/scrooge/framework", "spec/units/scrooge/framework/base_spec.rb", "spec/units/scrooge/framework/rails_spec.rb", "spec/units/scrooge/orm", "spec/units/scrooge/orm/base_spec.rb", "spec/units/scrooge/profile_spec.rb", "spec/units/scrooge/storage", "spec/units/scrooge/storage/base_spec.rb", "spec/units/scrooge/storage/memory_spec.rb", "spec/units/scrooge/strategy", "spec/units/scrooge/strategy/base_spec.rb", "spec/units/scrooge/strategy/controller_spec.rb", "spec/units/scrooge/strategy/scope_spec.rb", "spec/units/scrooge/strategy/stage_spec.rb", "spec/units/scrooge/strategy/track_spec.rb", "spec/units/scrooge/strategy/track_then_scope_spec.rb", "spec/units/scrooge/tracker", "spec/units/scrooge/tracker/app_spec.rb", "spec/units/scrooge/tracker/base_spec.rb", "spec/units/scrooge/tracker/model_spec.rb", "spec/units/scrooge/tracker/resource_spec.rb", "spec/units/scrooge_spec.rb", "rails/init.rb", "assets/config", "assets/config/scrooge.yml.template", "tasks/scrooge.rake"]
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
