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
  end

  def test_measure_instance_method
    # First test it with measure
    m=Perf::Meter.new

    a=PerfTestExample.new
    m.measure(:measure_test) { a.test(1,2,3) }
    m.measure(:measure_test_np) { a.test_np }

    # Then use the instance method
    m.measure_instance_method(PerfTestExample,:test)
    m.measure_instance_method(PerfTestExample,:test_np)
    m.measure_instance_method(PerfTestExample,:test)     # Do it twice and see what happens

    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np

    # Output the results
    rf=Perf::ReportFormatSimple.new
    puts rf.format(m)
    m.status
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
    m.count_value("test") { sleep(1) }
    m.count_value("test") { false }
    m.count_value("test") { false }
    #return if true
    puts "---- REPORT-----"
    rf=Perf::ReportFormatSimple.new
    puts rf.format(m)
  end
end