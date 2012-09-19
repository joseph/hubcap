require 'rake/testtask'

Rake::TestTask.new { |t|
  t.libs << 'test'
  t.test_files = FileList['test/unit/test*.rb']
  t.verbose = true
}

desc("Run tests")
task(:default => :test)
