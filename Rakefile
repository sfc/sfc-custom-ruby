require 'rubygems'
require 'echoe'

Echoe.new('sfc-custom') do |p|
  p.author = "SFC Limited, Inc."
  p.summary = "Library for accessing SFCcustom, a web service for generating dynamic content for print"
  p.dependencies = ["xml-simple"]
  p.project = "sfc"
  p.clean_pattern = ["pkg", "doc", 'build/*', '**/*.o', '**/*.so', '**/*.a', '**/*.log', "{ext,lib}/*.{bundle,so,obj,pdb,lib,def,exp}", "ext/Makefile", "{ext,lib}/**/*.{bundle,so,obj,pdb,lib,def,exp}", "ext/**/Makefile", "pkg", "*.gem", ".config"]
end