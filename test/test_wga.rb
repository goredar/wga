require 'test/unit'

FIX ||= false
NOOP ||=false

require 'wga'
LOG ||= Goredar::Logger.new STDERR

class WgaTestCase < Test::Unit::TestCase
  def test_can_load_config
    require File.expand_path("conf.rb", File.dirname(__FILE__))
    require 'securerandom'
    require 'yaml'
    file_name = File.expand_path("#{SecureRandom.hex}.yaml", "/tmp")
    File.open(file_name, "w") { |file| file.write YAML.dump CONF }
    assert_equal CONF, Wga.load_global_config(file_name)
    File.unlink file_name
  end
end
