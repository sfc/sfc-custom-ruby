require 'test/unit'
require 'lib/sfc-custom'

$rakefile = nil # Avoids a warning in rdoctask.rb

class TestSFCcustom < Test::Unit::TestCase
  def setup
    
  end

  def test_basics
    sfc = SFCCustom.new('44a568611beab6e76daef41a81f38ebe')
    assert sfc
    assert_kind_of(SFCCustom, sfc)
  end
end