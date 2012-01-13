#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

module Perf
  #
  # This class can be used in substitution to a Perf::Measure class to avoid overhead when performance measurments is not
  # required. It needs to maintain the same API as Perf::Measure.
  #
  class NoopMeasure

    def measurements
      {}
    end

    def current_stack
      {}
    end

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

  end

end