#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

module Perf

  # Simple Perf::Meter factory and singleton management.
  # Useful to not have to pass around Perf::Meter objects and still be able to generate stats in various parts of
  # the code.
  #
  class MeterFactory

    DEFAULT_METER = :default

    # Returns a Perf::Meter with a given key, and creates it lazly if it doesn't exist'.
    def self.get(key=DEFAULT_METER)
      @@perf_meters ||= {}
      @@perf_meters[key] ||= Perf::Meter.new
    end

    # Pushes a Perf::Meter into a key
    def self.set_meter(key,meter)
      @@perf_meters ||= {}
      @@perf_meters[key]=meter
    end

    # Sets the default meter.
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