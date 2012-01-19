# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rubyperf}
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["lpasqualis"]
  s.date = %q{2012-01-19}
  s.description = %q{Used to easily measure the performance of blocks of Ruby code, expressions and methods; provides reporting in various formats}
  s.email = %q{lpasqualis@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "MIT-LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/perf/measure.rb",
    "lib/perf/meter.rb",
    "lib/perf/meter_factory.rb",
    "lib/perf/no_op_meter.rb",
    "lib/perf/report_format.rb",
    "lib/perf/report_format_html.rb",
    "lib/perf/report_format_list_of_measures.rb",
    "lib/perf/report_format_simple.rb",
    "lib/rubyperf.rb",
    "rubyperf.gemspec",
    "test/helper.rb",
    "test/perf_test_example.rb",
    "test/rubyperf_test_helpers.rb",
    "test/test_meter_factory.rb",
    "test/test_no_op_meter.rb",
    "test/test_perf_meter.rb"
  ]
  s.homepage = %q{http://github.com/lpasqualis/rubyperf}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{rubyperf helps you measure ruby code performance}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

