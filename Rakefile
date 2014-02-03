require 'tmpdir'
require 'fileutils'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "*/**/*_spec.rb"
end

task :default => :spec
task :default => :greatest

desc "Run C tests"
task :greatest do
  Dir.mktmpdir do |d|
    test_suite_path = File.join(d, "test_suite.c")
    mk_test_suite_file(test_suite_path)

    args = "-pedantic -Wall -Wextra -Werror -std=c99 -Isupport/c/test -Isupport/c/src -I#{d}"
    srcs = "support/c/src/cauterize.c support/c/test/test.c"
    bin = File.join(d, "test.bin")
    sh "gcc #{args} #{srcs} -o #{bin}"
    sh bin
  end
end

desc "Run C# tests"
task :nunit do
  cd "support/cs" do
    FileUtils.mkdir_p "lib"
    sh "dmcs -target:library -out:lib/Cauterize.dll src/*.cs"
    references = "-r:lib/nunit.framework.dll -r:lib/Moq.dll -r:lib/Cauterize.dll"
    sh "dmcs -target:library #{references} -out:lib/Cauterize.Test.dll test/*.cs"
    sh "#{nunit} lib/*.dll"
  end
end

def nunit
  "nunit-console4"
end

# Support Methods

SUITE_ENTRY_TEMPLATE = "  RUN_TEST(%s);"

def mk_test_suite_file(path)
  test_files = Dir["support/c/test/*.c"]
  suite_text = test_files.map do |test_file|
    File.read(test_file).lines.map do |l|
      m = l.match(/^TEST (?<sym>[^\(]+)\(\)/)
      m ? m[:sym] : nil
    end.compact
  end.flatten.map {|t| SUITE_ENTRY_TEMPLATE % t}.join("\n") + "\n"

  File.open(path, "wb") {|fh| fh.write(suite_text)}
end
