#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require "rubyperf"

module Perf

  # Very simple Perf::Meter factory and singleton management.
  #
  # Useful to not have to pass around Perf::Meter objects and still be able to generate stats in various parts of
  # the code. For complex situations where you have multiple Perf::Meter objects you might need to consider
  # either creating a factory that fulfills your needs, or create Perf::Meter objects and pass them around or use
  # this factory will well planned out key values so that you won't have conflicts and overrides.
  #
  # MeterFactory works keeping a global cache of Perf::Meter objects by key. Multiple independent parts
  # of your code using this factory could get into trouble and trample on each other if they use the same key, or the
  # default key.
  #
  # Example of usage where it would be inconvenient to pass around the Perf::Meter object from example to function2:
  #
  # def example
  #   Perf::MeterFactory.get.measure(:function1)
  #     function1()
  #   end
  # end
  #
  # def function1()
  #    ..
  #    function2()
  #    ..
  # end
  #
  # def function2()
  #   ..
  #   Perf::MeterFactory.get.measure(:some_hot_code_in_function2)
  #     ...
  #   end
  #   ..
  # end
  #

  class MeterFactory

    DEFAULT_METER = :default

    @@perf_meters       = nil
    @@new_meter_options = {}
    @@factory_options   = {:noop=>false}

    # Returns a Perf::Meter with a given key, and creates it lazily if it doesn't exist'.
    # NOTE: The options are set ONLY the first time that get is called on a specific key.
    #       After that the options will be ignored!

    def self.get(key=DEFAULT_METER,new_meter_options=nil)
      @@perf_meters ||= {}
      if !@@factory_options[:noop]
        # Creates a real meter
        @@perf_meters[key] ||= Perf::Meter.new(new_meter_options || @@new_meter_options)
      else
        # If noop is set, creates a no-nop version of the meter, unless a meter with this key has already been
        # created.
        @@perf_meters[key] ||= Perf::NoOpMeter.new
      end
    end

    # meter is like get, but if the meter doesn't already exists it returns a NoOpMeter. You can use this every time
    # that you want "somebody else" make the decision of what meter to use.

    def self.meter(key=DEFAULT_METER)
      @@perf_meters ||= {}
      @@perf_meters[key] ||= Perf::NoOpMeter.new
    end

    # To set options for new meters created by get, when specific options are not passed, you can do so with this
    # method.

    def self.set_new_meters_options(options)
      @@new_meter_options.merge(options)
    end

    # Set options for the factory behaviour.

    def self.set_factory_options(options)
      @@factory_options.merge!(options)
    end

    # If you use set_new_meters_options, or if you pass options to Perf::MeterFactory.get, you are setting options
    # only for if the meter is created. For this reason you might need to find out if the meter already exist.

    def exists?(key=DEFAULT_METER)
      !@@perf_meters[key].nil?
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

    # Returns a hash of existing meters.

    def self.all
      @@perf_meters ||= {}
      return @@perf_meters.clone
    end

    # Removes an existing meter from the cache

    def self.clear_meter(key=DEFAULT_METER)
      @@perf_meters.delete(key) if @@perf_meters
    end

    # Clears the entire cache of meters.

    def self.clear_all!
      @@perf_meters=nil
    end

  end
end