module Perf
  #
  # This class can be used in substitution to a Perf::Measure class to avoid overhead when performance measurments is not
  # required. It needs to maintain the same API as Perf::Measure.
  #
  class NoOpMeter

    def initialize(logger = nil)
    end

    def clear
    end

    #############################################################################################################

    def measure(what,type=nil)
      yield
    end

    def count_value(what_to_count)
      nil
    end

    def report_arr(options={})
      []
    end

    def report(options={})
      true
    end

  end

end