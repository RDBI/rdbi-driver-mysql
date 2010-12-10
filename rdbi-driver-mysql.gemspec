# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rdbi-driver-mysql}
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Erik Hollensbe"]
  s.date = %q{2010-12-10}
  s.description = %q{mysql gem-based driver for RDBI}
  s.email = %q{erik@hollensbe.org}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/rdbi-driver-mysql.rb",
     "lib/rdbi/driver/mysql.rb",
     "rdbi-driver-mysql.gemspec",
     "test/helper.rb",
     "test/test_connect.rb",
     "test/test_database.rb",
     "test/test_statement.rb",
     "test/test_types.rb"
  ]
  s.homepage = %q{http://github.com/RDBI/rdbi-driver-mysql}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{mysql gem-based driver for RDBI}
  s.test_files = [
    "test/helper.rb",
     "test/test_connect.rb",
     "test/test_database.rb",
     "test/test_statement.rb",
     "test/test_types.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rdbi>, [">= 0"])
      s.add_runtime_dependency(%q<mysql>, [">= 2.8.1"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, [">= 0"])
      s.add_development_dependency(%q<rdbi-dbrc>, [">= 0"])
    else
      s.add_dependency(%q<rdbi>, [">= 0"])
      s.add_dependency(%q<mysql>, [">= 2.8.1"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<rdoc>, [">= 0"])
      s.add_dependency(%q<rdbi-dbrc>, [">= 0"])
    end
  else
    s.add_dependency(%q<rdbi>, [">= 0"])
    s.add_dependency(%q<mysql>, [">= 2.8.1"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<rdoc>, [">= 0"])
    s.add_dependency(%q<rdbi-dbrc>, [">= 0"])
  end
end
