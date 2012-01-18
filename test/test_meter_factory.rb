require "test/unit"

require 'helper'

require 'rubyperf'

require 'rubyperf_test_helpers'
require 'perf_test_example'

class TestMeterFactory < Test::Unit::TestCase

  def setup()
    Perf::MeterFactory.clear_all!
  end

  def teardown()
    Perf::MeterFactory.clear_all!
    Perf::MeterFactory.set_factory_options(:noop=>false)
  end

  def test_noop
    Perf::MeterFactory.set_factory_options(:noop=>true)
    m1=Perf::MeterFactory.get()
    assert m1.is_a? Perf::NoOpMeter
    m1.measure(:something) do
      # ...
    end
    assert m1.report_simple.nil?
  end

  def test_meter
    m=Perf::MeterFactory.meter
    assert m.is_a? Perf::NoOpMeter

    Perf::MeterFactory.clear_all!
    m=Perf::MeterFactory.get
    m=Perf::MeterFactory.meter
    assert m.is_a? Perf::Meter
  end

  def test_noop2
    Perf::MeterFactory.set_factory_options(:noop=>true)
    m=Perf::MeterFactory.get()
    assert m.is_a? Perf::NoOpMeter
    m.measure(:string_operations) do
      m.measure(:ciao) do
        10.times do; "CIAO"*100; end
      end
    end
    m.measure(:string_operations) do
      m.measure(:help) do
        10.times do; "HELP"*100; end
      end
    end
    m.measure(:emtpy_loop) do
      500.times do; end;
    end
    m.measure(:rough_overhead_x10000) do
      10.times do
        m.measure(:block_1) do
          m.measure(:block_1_1) do
          end
          m.measure(:block_1_2) do
            m.measure(:block_1_2_1) do
            end
            m.measure(:block_1_2_2) do
            end
            m.measure(:block_1_2_3) do
              assert_equal false,m.measure_result(:bool_exp_1_2_3) { false }
              m.measure_result(:bool_exp_1_2_3) { true }
            end
          end
        end
      end
    end

    m.measure(:empty) do
    end
    m.measure_result("test") { "something" }
    m.measure_result("test") { false }
    m.measure_result("test") { false }

    m.method_meters(Array,[:sort,:reverse],[:new]) do
      Array.new(1000000,"abc").reverse.sort
    end
    assert_equal 123,m.measure(:blah) {123}
    assert m.report_simple.nil?
  end

  def test_basic
    Perf::MeterFactory.clear_all!
    m1=Perf::MeterFactory.get()
    m2=Perf::MeterFactory.get()

    m1.measure(:a) {}
    m1.measure(:b) {}

    assert m1.eql?(m2)
    assert_equal 3, m2.measurements.count
    assert_equal 3, m1.measurements.count
    assert_equal 1,Perf::MeterFactory.all.length

    m3=Perf::MeterFactory.get(:some_meter)
    m4=Perf::MeterFactory.get(:some_meter)

    assert m3.eql? m4
    assert !(m1.eql? m3)
    assert_equal 2,Perf::MeterFactory.all.length

    Perf::MeterFactory.clear_meter(:some_meter)
    assert_equal 1,Perf::MeterFactory.all.length

    Perf::MeterFactory.clear_all!
    assert_equal 0,Perf::MeterFactory.all.length

    ameter = Perf::Meter.new
    Perf::MeterFactory.set_meter(:ameter,ameter)
    assert (ameter.eql? Perf::MeterFactory.get(:ameter))

    Perf::MeterFactory.set_default(ameter)
    assert (ameter.eql? Perf::MeterFactory.get)
  end

end