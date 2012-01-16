#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require "test/unit"

require 'helper'

require 'rubyperf'

require 'rubyperf_test_helpers'
require 'perf_test_example'

class TestMeterFactory < Test::Unit::TestCase

  def test_noop
    Perf::MeterFactory.clear_all!
    Perf::MeterFactory.set_factory_options(:noop=>true)
    m1=Perf::MeterFactory.get()
    assert m1.is_a? Perf::NoOpMeter
    m1.measure(:something) do
      # ...
    end
    assert m1.report_simple.nil?
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