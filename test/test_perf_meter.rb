require "test/unit"

require 'helper'
require 'rubyperf'

class TestPerfMeter < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  class PerfTestExample
    def test(a,b,c)
      (0..100000).to_a.reverse.reverse.reverse # Do something heavy
    end

    def test_np
      (0..300000).to_a.reverse.reverse.reverse # Do something heavy
    end

    def self.static_method
      (0..300000).to_a.reverse.reverse.reverse # Do something heavy
    end
  end

  def get_measure
    m=Perf::Meter.new

    a=PerfTestExample.new
    m.measure(:measure_test) { a.test(1,2,3) }
    m.measure(:measure_test_np) { a.test_np }
    m.measure(:some_expressions) do
      m.measure_result(:expression1) { 1234+12345 }
      m.measure_result(:expression1) { 1234-123 }
      m.measure_result(:expression2) { "string" }
    end
    # Then use the instance method
    m.measure_instance_method(PerfTestExample,:test)
    m.measure_instance_method(PerfTestExample,:test_np)
    m.measure_instance_method(PerfTestExample,:test)     # Do it twice and see what happens
    m.measure_class_method(PerfTestExample,:static_method)
    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np
    PerfTestExample.static_method
    m
  end

  def test_output_html
    # First test it with measure
    m=get_measure
    rf=Perf::ReportFormatHtml.new
    puts rf.format(m)
    m.restore_all_methods(PerfTestExample)
  end

  def test_measure_instance_method
    # First test it with measure
    m=Perf::Meter.new

    a=PerfTestExample.new
    m.measure(:measure_test) { a.test(1,2,3) }
    m.measure(:measure_test_np) { a.test_np }
    m.measure(:some_expressions) do
      m.measure_result(:expression1) { 1234+12345 }
      m.measure_result(:expression1) { 1234-123 }
      m.measure_result(:expression2) { "string" }
    end
    # Then use the instance method
    m.measure_instance_method(PerfTestExample,:test)
    m.measure_instance_method(PerfTestExample,:test_np)
    m.measure_instance_method(PerfTestExample,:test)     # Do it twice and see what happens
    m.measure_class_method(PerfTestExample,:static_method)

    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np
    PerfTestExample.static_method

    # Output the results
    rf=Perf::ReportFormatSimple.new
    puts rf.format(m)

    puts "\nRestoring test:\n\n"

    m.restore_instance_method(PerfTestExample,:test)
    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np
    puts rf.format(m)

    m.restore_all_instance_methods(PerfTestExample)
    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np
    puts rf.format(m)
    m.restore_all_methods(PerfTestExample)
  end

  def test_basic
    m=Perf::Meter.new
    m.measure(:string_operations) do
      m.measure(:ciao1000) do
        10000.times do; "CIAO"*1000; end
      end
    end
    m.measure(:string_operations) do
      m.measure(:help1000) do
        10000.times do; "HELP"*1000; end
      end
    end
    m.measure(:emtpy_loop) do
      50000.times do; end;
    end
    m.measure(:measure_overhead_x10000) do
      1000.times do
        m.measure(:nothing1) do
          m.measure(:blah2) do
          end
          m.measure(:nothing2) do
            m.measure(:nothing3) do
            end
            m.measure(:blah3) do
            end
            m.measure(:zzzzblah3) do
              m.measure_result(:bool) { false }
              m.measure_result(:bool) { true }
            end
          end
        end
      end
    end

    m.measure(:something) do
      m.measure(:something1) do
        sleep(0.2)
      end
      m.measure(:something2) do
        sleep(0.3)
      end
      m.measure(:something2) do
        sleep(0.01)
      end
    end
    m.measure(:fast) do
    end
    m.measure_result("test") { sleep(1) }
    m.measure_result("test") { false }
    m.measure_result("test") { false }
    rf=Perf::ReportFormatSimple.new
    puts rf.format(m)
  end
end