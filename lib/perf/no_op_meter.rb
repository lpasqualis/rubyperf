#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require "rubyperf"

module Perf
  #
  # This class can be used in substitution to a Perf::Meter class to avoid overhead when performance measurements is not
  # required. It needs to maintain the same API as Perf::Meter.
  #
  class NoOpMeter

    def initialize(options=nil)
    end

    def clear
    end

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

    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^report_(.*)$/
        klass=Object.const_get("Perf").const_get("ReportFormat#{$1.capitalize}")
        return nil if klass
      end
      super
    end

  end

end