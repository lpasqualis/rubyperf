#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require 'rubyperf'
require 'perf_test_example'

class RubyperfTestHelpers
  def self.get_measure
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
    m.method_meters(PerfTestExample,[:test,:test_np],[:static_method]) do
      a=PerfTestExample.new
      a.test(1,2,3)
      a.test_np
      PerfTestExample.static_method
    end
    m
  end

  def self.verify_report(m,expected_paths)
    rf=Perf::ReportFormat.new
    r=rf.format(m)
    cnt=0
    expected_paths.each do |ep|
      r.each do |l|
        cnt+=1 if l[:title]==ep
      end
    end
    cnt==expected_paths.size
  end

end