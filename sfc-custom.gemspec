Gem::Specification.new do |s|
  s.name = %q{sfc-custom}
  s.version = "0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["SFC Limited, Inc."]
  s.date = %q{2008-11-17}
  s.description = %q{Library for accessing SFCcustom, a web service for generating dynamic content for print}
  s.email = %q{kmarsh@formandfx.com}
  s.files = ["CHANGELOG", "lib/sfc-custom.rb", "LICENSE", "Manifest", "Rakefile", "README", "test/fixtures/expected_output_for_test_personalized_vps_order_with_logo.xml", "test/fixtures/expected_output_for_test_personalized_vps_order_with_text.xml", "test/fixtures/expected_output_for_test_standard_vps_order.xml", "test/test_sfc-custom.rb", "sfc-custom.gemspec"]
  s.homepage = %q{}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sfc}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Library for accessing SFCcustom, a web service for generating dynamic content for print}
  s.test_files = ["test/test_sfc-custom.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<xml-simple>, [">= 0"])
    else
      s.add_dependency(%q<xml-simple>, [">= 0"])
    end
  else
    s.add_dependency(%q<xml-simple>, [">= 0"])
  end
end