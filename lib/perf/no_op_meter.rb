#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

module Perf
  #
  # This class can be used in substitution to a Perf::Meter class to avoid overhead when performance measurements is not
  # required. It needs to maintain the same API as Perf::Meter.
  #
  class NoOpMeter

    def initialize(logger = nil)
    end

    def clear
    end

    #############################################################################################################

    def measure(what,&code)
      yield
    end

    def  measure_result(what,&code)
      yield
    end

    def method_meters(klass,imethods=[],cmethods=[])
      yield
    end

    def measure_instance_method(klass,method_name)
    end

    def measure_instance_method(klass,method_name)
    end

    def restore_all_instance_methods(klass)
    end

    def measure_class_method(klass,method_name)
    end

    def restore_class_method(klass,method_name)
    end

    def restore_all_class_methods(klass)
    end

    def restore_all_methods(klass)
    end

    def measure_full_path(path,&code)
      yield
    end

  end

end