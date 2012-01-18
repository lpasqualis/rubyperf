require "test/unit"

require 'helper'

require 'rubyperf'

require 'rubyperf_test_helpers'
require 'perf_test_example'

class TestNoOpMeter < Test::Unit::TestCase

  def test_basic
    m=Perf::NoOpMeter.new
    assert !m.has_measures?
    v=m.measure(:a) do
      m.measure(:b) do
        123
      end
    end
    assert_equal 123,v

    m.method_meters(PerfTestExample,[:test,:test_np,:test_with_measure],[:static_method]) do
      a=PerfTestExample.new
      a.test(1,2,3)
      a.test_np
      a.test_with_measure
      PerfTestExample.static_method
    end

    assert_nil m.report_html
    assert_nil m.report_simple
    assert_nil m.report_list_of_measures
    error=false
    begin
      m.report_this_does_not_exists
    rescue
      error=true
    end
    assert error
    assert_nil m.measurements
    assert_nil m.current_path

    assert_equal 123,m.measure_result(:something) {123}
    assert_equal 123,m.measure_result(:something) {m.measure(:blah){123}}
  end


end