require 'rubyperf'

module Perf
  class Measure
    attr_accessor :path
    attr_accessor :count
    attr_accessor :time
    attr_accessor :measuring

    def initialize(measure_path)
      @path      = measure_path
      @count     = 0
      @time      = Benchmark::Tms.new
      @measuring = false
    end

    def merge(m)
      @count      +=  m.count
      @time       +=  m.time
      @measuring  ||= m.measuring
    end

  end
end