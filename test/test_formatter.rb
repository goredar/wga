require 'test/unit'

FIX ||= false
NOOP ||=false

require 'wga'

LOG ||= Goredar::Logger.new STDERR

class FormatterTestCase < Test::Unit::TestCase
  def test_can_add_all_units_with_args
    f = Wga::Formatter.new
    Wga::Formatter::UNITS.each do |unit|
      f.public_send unit, "test string for #{unit}"
    end
    assert_equal Wga::Formatter::UNITS.count, f.units.count
    f.units.each { |unit| assert_equal "test string for #{unit.first}", unit[1] }
  end
  def test_can_add_all_units_with_block
    f = Wga::Formatter.new
    Wga::Formatter::UNITS.each do |unit|
      f.public_send(unit) { "test string for #{unit}" }
    end
    assert_equal Wga::Formatter::UNITS.count, f.units.count
    f.units.each { |unit| assert_equal "test string for #{unit.first}", unit[1] }
  end
  def test_can_add_all_units_with_args_and_block
    f = Wga::Formatter.new
    Wga::Formatter::UNITS.each do |unit|
      f.public_send(unit, "test string for #{unit}") { "test string for #{unit}" }
    end
    assert_equal Wga::Formatter::UNITS.count * 2, f.units.count
    f.units.each { |unit| assert_equal "test string for #{unit.first}", unit[1] }
  end
end
