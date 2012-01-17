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

    assert_equal ['\blocks,10',
    '\blocks\empty,1',
    '\blocks\emtpy_loop,1',
    '\blocks\rough_overhead_x10000,1',
    '\blocks\rough_overhead_x10000\block_1,1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_1,1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_2,1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_2\block_1_2_1,1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_2\block_1_2_2,1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_2\block_1_2_3,1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_2\block_1_2_3\bool_exp_1_2_3 = "false",1000',
    '\blocks\rough_overhead_x10000\block_1\block_1_2\block_1_2_3\bool_exp_1_2_3 = "true",1000',
    '\blocks\sleep1,1',
    '\blocks\sleep1\sleep1_1,1',
    '\blocks\sleep1\sleep_1_2,1',
    '\blocks\sleep1\sleep_1_3,1',
    '\blocks\string_operations,2',
    '\blocks\string_operations\ciao,1',
    '\blocks\string_operations\help,1',
    '\blocks\test = "1",1',
    '\blocks\test = "false",2',
    '\methods,3',
    '\methods\#<Class:Array>.new,1',
    '\methods\Array.reverse,1',
    '\methods\Array.sort,1'],
    m.report_list_of_measures
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

    assert_equal 6,m.report_simple.length
    assert_equal 6,m.report_html(:percent_format=>"%.8f").length
    assert_equal 6,m.report_html.length
    assert_equal ['\methods,3',
                  '\methods\#<Class:PerfTestExample>.static_method,1',
                  '\methods\PerfTestExample.test,1',
                  '\methods\PerfTestExample.test_np,1'],
                m.report_list_of_measures
  end

  def test_has_measures
    m=Perf::Meter.new
    assert !m.has_measures?
    m.measure(:a) {assert m.has_measures?}
    assert m.has_measures?
  end

  def test_accurancy
    m=Perf::Meter.new
    m.measure(:b) do
    end
    m.measure(:a) do
      ("123"*1_000_000).reverse
    end
    assert m.accuracy(m.measurements['\blocks'].path) >= 0
    assert m.accuracy(m.measurements['\blocks\a'].path) >= 0
    assert m.accuracy(m.measurements['\blocks\b'].path) < 0
    assert_equal 2,m.report_list_of_measures(:filter_below_accuracy=>0.0001).length
    assert_equal 2,m.report_list_of_measures(:filter_below_percent=>1).length
    assert_equal 3,m.report_list_of_measures(:filter_below_accuracy=>-10).length
    assert_equal 3,m.report_list_of_measures(:filter_below_percent=>-10).length
  end

  def test_filters
    m=Perf::Meter.new
    m.measure(:a) do
      sleep(0.2)
    end
    m.measure(:b) do
      sleep(0.1)
    end
    m.measure(:c) do
      sleep(0.0001)
    end
    assert_equal 4,m.report_list_of_measures.length
    assert_equal 3,m.report_list_of_measures(:filter_below_accuracy=>1).length
    assert_equal 3,m.report_list_of_measures(:filter_below_accuracy=>500).length
    assert_equal 3,m.report_list_of_measures(:filter_below_percent=>10).length
    assert_equal 2,m.report_list_of_measures(:filter_below_percent=>45).length
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
    assert_equal 10,m.report_simple.length
    assert_equal 10,m.report_html.length
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
  end

  def test_exception_handling
    # An exception thrown in a block that we are measuring needs to leave the Perf::Meter in a good state.
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
  end

  def test_nesting_measure
    m=Perf::Meter.new
    m.measure(:a) { }
    m.measure(:b) { }
    m.measure(:d) { m.measure(:c) { m.measure(:d) {} }}

    assert_equal ['\blocks,3',
                  '\blocks\a,1',
                  '\blocks\b,1',
                  '\blocks\d,1',
                  '\blocks\d\c,1',
                  '\blocks\d\c\d,1'],
         m.report_list_of_measures
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
    assert_equal ['\blocks,3',
                  '\blocks\measure_test,1',
                  '\blocks\measure_test_np,1',
                  '\blocks\some_expressions,1',
                  '\blocks\some_expressions\expression1 = "1111",1',
                  '\blocks\some_expressions\expression1 = "13579",1',
                  '\blocks\some_expressions\expression2 = "string",1',
                  '\methods,5',
                  '\methods\#<Class:PerfTestExample>.static_method,1',
                  '\methods\PerfTestExample.test,1',
                  '\methods\PerfTestExample.test_np,2'],
                  m.report_list_of_measures
  end


  def test_overhead
    runs=1_000
    a=(1..100_000).to_a
    m_no_overhead=Perf::Meter.new(:subtract_overhead=>true)
    b1_no_overhead=Benchmark.measure { runs.times { m_no_overhead.measure(:a) { a.reverse! } } }
    b2_no_overhead=Benchmark.measure { runs.times { a.reverse!                 } }

    m_yes_overhead=Perf::Meter.new(:subtract_overhead=>false)
    b1_yes_overhead=Benchmark.measure { runs.times { m_yes_overhead.measure(:a) { a.reverse! } } }
    b2_yes_overhead=Benchmark.measure { runs.times { a.reverse!                 } }


    assert_equal  ['\blocks,500500',
                   '\blocks\a,1000'],
                  m_no_overhead.report_list_of_measures

    assert_equal  m_no_overhead.report_list_of_measures,
                  m_yes_overhead.report_list_of_measures

    # TODO: find the magic assert that ensures that the overhead calculation is correct. Ensure that such assert
    #       is machine independent and that will pass the test of time (new hardware getting faster and faster)

    #calculated_overhead_1= (b1_no_overhead-b2_no_overhead)/runs
    #calculated_overhead_2= (b1_yes_overhead-b2_yes_overhead)/runs
    #
    #puts (calculated_overhead_1-m_no_overhead.overhead)
    #puts (calculated_overhead_2-m_yes_overhead.overhead)
    #
    #puts m_no_overhead.report_simple
    #puts m_yes_overhead.report_simple
    #
    #assert m_no_overhead.blocks_time.total > m_yes_overhead.blocks_time.total
  end
end