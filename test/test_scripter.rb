require 'test/unit'
require File.expand_path("conf.rb", File.dirname(__FILE__))

FIX ||= false
NOOP ||=false

require 'wga'
LOG ||= Goredar::Logger.new STDERR

class WgaScripterTestCase < Test::Unit::TestCase
  TEST_SCRIPT = %Q(
    description "Test Script"
    pattern /_test_script_/

    script :test_script do
    section "test action"
      sh 'cd /tmp'
      sh 'pwd'
    end
  )
  def test_can_add_script
    scripts_count = Wga::Scripter.scripts.count
    assert_true Wga::Scripter.add_script TEST_SCRIPT
    assert_equal scripts_count + 1, Wga::Scripter.scripts.count
    assert_equal "Test Script", Wga::Scripter.scripts.fetch(:test_script)[:description]
    assert_equal /_test_script_/, Wga::Scripter.scripts.fetch(:test_script)[:pattern]
    assert_not_nil Wga::Scripter.scripts.fetch(:test_script)[:block]
    # Avoid duplication
    assert_false Wga::Scripter.add_script TEST_SCRIPT
    assert_equal scripts_count + 1, Wga::Scripter.scripts.count
  end

  def test_can_run_script
    Wga::Scripter.add_script TEST_SCRIPT
    args =
        [
          ['localhost', :test_script],
          ['localhost', [:test_script]],
          ['localhost', {:name => :test_script}],
          ['localhost', [{:name => :test_script}]],
        ]
    args.each do |arg|
      out = Wga::Scripter.run(*arg).to_s.split($/)
      assert_equal "test action", out[0]
      assert out[1].include? 'cd /tmp'
      assert out[2].include? 'pwd'
      assert_equal "/tmp", out[3]
    end
  end

  def test_can_run_several_scripts
    args = ['localhost', [{:name => :test_script}, {:name => :test_script}]]
    out = Wga::Scripter.run(*args).to_s
  end
end
