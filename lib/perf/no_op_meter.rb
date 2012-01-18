require "rubyperf"

module Perf
  #
  # This class can be used in substitution to a Perf::Meter class to avoid overhead when performance measurements is not
  # required. It needs to maintain the same API as Perf::Meter.
  #
  class NoOpMeter

    def measurements
    end

    def current_path
    end

    def has_measures?
      false
    end

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

    def restore_instance_method(klass,method_name)
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

    def overhead
      Benchmark::Tms.new
    end

    # Returns the total time - expressed with a Benchmark::Tms object - for all the blocks measures
    def blocks_time
      Benchmark::Tms.new
    end

    # Returns the total time - expressed with a Benchmark::Tms object - for all the methods measures
    def methods_time
      Benchmark::Tms.new
    end

    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^report_(.*)$/
        klass=Object.const_get("Perf").const_get("ReportFormat#{camelize($1)}")
        return nil if klass
      end
      super
    end

    def camelize(from)
      from.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

  end

end