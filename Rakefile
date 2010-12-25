require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rdbi-driver-mysql"
    gem.summary = %Q{mysql gem-based driver for RDBI}
    gem.description = %Q{mysql gem-based driver for RDBI}
    gem.email = "erik@hollensbe.org"
    gem.homepage = "http://github.com/RDBI/rdbi-driver-mysql"
    gem.authors = ["Erik Hollensbe"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.add_dependency 'rdbi'
    gem.add_dependency 'mysql', '>= 2.8.1'

    gem.add_development_dependency 'test-unit'
    gem.add_development_dependency 'rdoc'
    gem.add_development_dependency 'rdbi-dbrc'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
rescue LoadError
  task :roodi do
    abort "Roodi is not available. In order to run roodi, you must: sudo gem install roodi"
  end
end

begin
  require 'reek/rake/task'
  Reek::Rake::Task.new do |t|
    t.reek_opts << '-q'
  end
rescue LoadError
  task :reek do
    abort "Reek is not available. 'gem install reek'."
  end
end

task :default => :test

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rdbi-dbd-mysql #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
