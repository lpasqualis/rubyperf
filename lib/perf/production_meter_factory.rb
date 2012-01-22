require "rubyperf"

module Perf
  class ProductionMeterFactory

    def self.instance
      Perf::MeterFactory.instance.no_op_instance
    end

  end
end
