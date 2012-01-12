module Perf
  class MeterFactory

    DEFAULT_METER = :default

    def self.get(key=DEFAULT_METER)
      @@perf_meters ||= {}
      @@perf_meters[key] ||= Perf::Meter.new
    end

    def self.set_meter(key,meter)
      @@perf_meters ||= {}
      @@perf_meters[key]=meter
    end

    def self.set_default(meter)
      set_meter(DEFAULT_METER,meter)
    end

    def self.all
      @@perf_meters ||= {}
      return @@perf_meters.clone
    end

    def self.clear_meter(key=DEFAULT_METER)
      @@perf_meters.delete(key) if @@perf_meters
    end

    def self.clear_all!
      @@perf_meters=nil
    end

  end
end