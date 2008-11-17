require 'test/unit'

module Kernel
  def __method__
    caller[0][/`([^']*)'/, 1]
  end
end

$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))
require 'sfc-custom'

$rakefile = nil # Avoids a warning in rdoctask.rb

class TestSFCcustom < Test::Unit::TestCase
  def setup
    
  end

  def test_basics
    sfc = SFCcustom.new('44a568611beab6e76daef41a81f38ebe')
    assert sfc
    assert_kind_of(SFCcustom, sfc)
  end
  
  def test_personalized_vps_order_with_logo
    custom = SFCcustom.new('92be4756d943439c73f20ec165bacca9')
    blocks = {
      "TEXT_BARCODE" => "*CT-04191-1-1*",
      "TEXT_SKU"     => "09PRESBI-001",
      "PDF_CONTRACTOR_TYPE" => {
        "template"                    => "Logo_Only",
        "PDF_CONTRACTOR_LOGO"         => "http://ctsamples.com/logos/0000/0389/7bc10cce32aaa4287d4fc0c1ded49627.pdf",
        "TEXT_ADDITIONAL_INFORMATION" => ""
      }
    }

    output = custom.build_request("GenerateCustom", { :name => "LMSERIESNW_back", :data => blocks, :resize => nil, :cache => false, :copy => nil, :thumbnail => false})
    
    expected = File.open(File.join(File.dirname(__FILE__), 'fixtures', "expected_output_for_#{__method__}.xml")).read
  
    assert_equal expected, output
  end
  
  def test_personalized_vps_order_with_text
    custom = SFCcustom.new('92be4756d943439c73f20ec165bacca9')
    blocks = {
      "TEXT_BARCODE"  => "*CT-03037-1-1*",
      "TEXT_SKU"      => "LMSERIESNW-002",
      "PDF_CONTRACTOR_TYPE" => {
        "template"                    => "SMC",
        "TEXT_CONTRACTOR_NAME"        => "www.customquality.net",
        "TEXT_ADDITIONAL_INFORMATION" => %Q(<avoidbreak=true>472-2282<avoidbreak=false>
<avoidbreak=true>Custom Quality <avoidbreak=false>
<avoidbreak=true>Construction Inc<avoidbreak=false>)
      }
    }
    output = custom.build_request("GenerateCustom", { :name => "LMSERIESNW_back", :data => blocks, :resize => nil, :cache => false, :copy => nil, :thumbnail => false})
    
    expected = File.open(File.join(File.dirname(__FILE__), 'fixtures', "expected_output_for_#{__method__}.xml")).read
  
    assert_equal expected, output
  end
  
  def test_standard_vps_order
    # This is not abstracted from a real order
    custom = SFCcustom.new('92be4756d943439c73f20ec165bacca9')
    blocks = {
      "TEXT_BARCODE" => "*CT-XXXXX-1-1*",
      "TEXT_SKU"     => "09LMPREMAV-004",
    }
    output = custom.build_request("GenerateCustom", { :name => "LMSERIESNW_back", :data => blocks, :resize => nil, :cache => false, :copy => nil, :thumbnail => false})
    
    expected = File.open(File.join(File.dirname(__FILE__), 'fixtures', "expected_output_for_#{__method__}.xml")).read
  
    assert_equal expected, output
  end
  
end