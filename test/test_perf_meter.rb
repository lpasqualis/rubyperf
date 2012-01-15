#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require "test/unit"
require 'helper'
require 'rubyperf'
require 'rubyperf_test_helpers'
require 'perf_test_example'

class TestPerfMeter < Test::Unit::TestCase

  ALLOW_OUTPUT = false

  def test_overhead
    runs=10000
    m=Perf::Meter.new
    b1=Benchmark.measure { runs.times { m.measure(:a) { } } }
    b2=Benchmark.measure { runs.times {                   } }

    puts b1      if ALLOW_OUTPUT
    puts b2      if ALLOW_OUTPUT
    puts b1-b2   if ALLOW_OUTPUT
  end

  def test_method_not_corrupted_after_restoring
    m=Perf::Meter.new
    imethods=PerfTestExample.new.methods.sort
    cmethods=PerfTestExample.methods.sort
    m.method_meters(PerfTestExample,[:test,:test_np],[:static_method]) do
      a=PerfTestExample.new
      a.test(1,2,3)
      a.test_np
      PerfTestExample.static_method
    end
    assert PerfTestExample.methods.sort     == cmethods
    assert PerfTestExample.new.methods.sort == imethods
    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_method_metering
    m=Perf::Meter.new
    m.method_meters(PerfTestExample,[:test,:test_np],[:static_method]) do
      a=PerfTestExample.new
      a.test(1,2,3)
      a.test_np
      PerfTestExample.static_method
    end
    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_methods_with_measure
    Perf::MeterFactory.clear_all!
    m=Perf::MeterFactory.get
    m.method_meters(PerfTestExample,[:test,:test_np,:test_with_measure],[:static_method]) do
      a=PerfTestExample.new
      a.test(1,2,3)
      a.test_np
      a.test_with_measure
      PerfTestExample.static_method
    end
    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_base_report
    m=Perf::Meter.new
    m.measure(:a) { }
    m.measure(:b) { }
    m.measure(:d) { m.measure(:c) { m.measure(:d) {} }}

    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\d\\c\\d"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\d\\c"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\d"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\b"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\a"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}"]
    assert_equal 6,m.measurements.size

    assert_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\huh"]
    assert RubyperfTestHelpers.verify_report(m,["#{Perf::Meter::PATH_MEASURES}\\d\\c\\d",
                                                "#{Perf::Meter::PATH_MEASURES}\\d\\c",
                                                "#{Perf::Meter::PATH_MEASURES}\\d",
                                                "#{Perf::Meter::PATH_MEASURES}\\b",
                                                "#{Perf::Meter::PATH_MEASURES}"])
    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_output_html
    m=RubyperfTestHelpers.get_measure
    htmlcode=m.report_html
    puts htmlcode if ALLOW_OUTPUT
  end

  def test_exception_handling
    # An exeption thwon in a block that we are measuring needs to leave the Perf::Meter in a good state.
    # This test checks the state after an exception.
    exception_raised  = false
    measuring_correct = false
    stack_correct     = false
    m=Perf::Meter.new

    begin
      m.measure(:some_exception) do
        sleep 0.2
        a=12/0   # Divide by zero
        sleep 0.2
      end
    rescue
      exception_raised=true
    ensure
      measuring_correct=true
      m.measurements.each_pair do |_,x|
        measuring_correct=false if x.measuring?
      end
      stack_correct = m.current_path.nil?
    end
    assert exception_raised
    assert measuring_correct
    assert stack_correct
    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_return_values
    m=Perf::Meter.new

    assert_equal 4,m.measure(:four) {4}
    assert_equal "hello",m.measure(:hello) {"hel"+"lo"}

    assert_equal 5,m.measure_result(:five) {5}
    assert_equal "byebye",m.measure_result(:byebye) {"bye"+"bye"}

    m.measure(:in_here_too) do
      assert_equal 5,m.measure_result(:five) {5}
      assert_equal "byebye",m.measure_result(:byebye) {"bye"+"bye"}
    end

    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_nesting_measure
    m=Perf::Meter.new
    m.measure(:a) { }
    m.measure(:b) { }
    m.measure(:d) { m.measure(:c) { m.measure(:d) {} }}
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\d\\c\\d"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\d\\c"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\d"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\b"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\a"]
    assert_not_nil m.measurements["#{Perf::Meter::PATH_MEASURES}"]
    assert_nil m.measurements["#{Perf::Meter::PATH_MEASURES}\\huh"]
    puts m.report_simple if ALLOW_OUTPUT
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
    #puts m.report_simple(m)

    #puts "\nRestoring test:\n\n"

    m.restore_instance_method(PerfTestExample,:test)
    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np
    #puts m.report_simple

    m.restore_all_instance_methods(PerfTestExample)
    a=PerfTestExample.new
    a.test(1,2,3)
    a.test_np
    #puts puts m.report_simple
    m.restore_all_methods(PerfTestExample)
    puts m.report_simple if ALLOW_OUTPUT
  end

  def test_basic
    m=Perf::Meter.new
    m.measure(:string_operations) do
      m.measure(:ciao) do
        1000.times do; "CIAO"*100; end
      end
    end
    m.measure(:string_operations) do
      m.measure(:help) do
        1000.times do; "HELP"*100; end
      end
    end
    m.measure(:emtpy_loop) do
      50000.times do; end;
    end
    m.measure(:rough_overhead_x10000) do
      1000.times do
        m.measure(:block_1) do
          m.measure(:block_1_1) do
          end
          m.measure(:block_1_2) do
            m.measure(:block_1_2_1) do
            end
            m.measure(:block_1_2_2) do
            end
            m.measure(:block_1_2_3) do
              m.measure_result(:bool_exp_1_2_3) { false }
              m.measure_result(:bool_exp_1_2_3) { true }
            end
          end
        end
      end
    end

    m.measure(:sleep1) do
      m.measure(:sleep1_1) do
        sleep(0.01)
      end
      m.measure(:sleep_1_2) do
        sleep(0.02)
      end
      m.measure(:sleep_1_3) do
        sleep(0.03)
      end
    end
    m.measure(:empty) do
    end
    m.measure_result("test") { sleep(1) }
    m.measure_result("test") { false }
    m.measure_result("test") { false }

    m.method_meters(Array,[:sort,:reverse],[:new]) do
      Array.new(1000000,"abc").reverse.sort
    end

    puts m.report_simple if ALLOW_OUTPUT

  end
end