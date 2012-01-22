require "rubyperf"
require "singleton"

module Perf

  # Very simple Perf::Meter factory and singleton management.
  #
  # Useful to not have to pass around Perf::Meter objects and still be able to generate stats in various parts of
  # the code. For complex situations where you have multiple Perf::Meter objects you might need to consider
  # either creating a factory that fulfills your needs, or create Perf::Meter objects and pass them around or use
  # this factory will well planned out key values so that you won't have conflicts and overrides.
  #
  # Example of usage where it would be inconvenient to pass around the Perf::Meter object from example to function2:
  #
  # def example
  #   Perf::MeterFactory.instance.get.measure(:function1)
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
  #   Perf::MeterFactory.instance.get.measure(:some_hot_code_in_function2)
  #     ...
  #   end
  #   ..
  # end
  #

  class MeterFactory
    include Singleton

    DEFAULT_METER = :default

    def initialize
      @perf_meters       = {}
      @new_meter_options = {}
      @factory_options   = {:noop=>false}
    end

    # Returns a Perf::Meter with a given key, and creates it lazily if it doesn't exist'.
    # NOTE: The options are set ONLY the first time that get is called on a specific key.
    #       After that the options will be ignored!

    def get(key=DEFAULT_METER,new_meter_options=nil)
      if !@factory_options[:noop]
        # Creates a real meter
        @perf_meters[key] ||= Perf::Meter.new(new_meter_options || @new_meter_options)
      else
        # If noop is set, creates a no-nop version of the meter, unless a meter with this key has already been
        # created.
        @perf_meters[key] ||= Perf::NoOpMeter.new
      end
    end

    # meter is like get, but if the meter doesn't already exists it returns a NoOpMeter. You can use this every time
    # that you want "somebody else" make the decision of what meter to use.

    def meter(key=DEFAULT_METER)
      @perf_meters[key] ||= Perf::NoOpMeter.new
    end

    # To set options for new meters created by get, when specific options are not passed, you can do so with this
    # method.

    def set_new_meters_options(options)
      @new_meter_options.merge(options)
    end

    # Set options for the factory behaviour.

    def set_factory_options(options)
      @factory_options.merge!(options)
    end

    # Clear factory options.

    def clear_factory_options!
      @factory_options.clear
    end

    # If you use set_new_meters_options, or if you pass options to Perf::MeterFactory.get, you are setting options
    # only for if the meter is created. For this reason you might need to find out if the meter already exist.

    def exists?(key=DEFAULT_METER)
      !@perf_meters[key].nil?
    end

    # Pushes a Perf::Meter into a key

    def set_meter(key,meter)
      @perf_meters[key]=meter
    end

    # Sets the default meter.

    def set_default(meter)
      set_meter(DEFAULT_METER,meter)
    end

    # Returns a hash of existing meters.

    def all
      @perf_meters.dup
    end

    # Removes an existing meter from the cache

    def clear_meter(key=DEFAULT_METER)
      @perf_meters.delete(key) if @perf_meters
    end

    # Clears the entire cache of meters.

    def clear_all!
      @perf_meters.clear
    end

    # Used by ProductionMeterFactory to return the instance ensuring that no Perf::Meters will be created if they
    # do not exist.

    def no_op_instance
      @factory_options[:noop] = true
      self
    end

  end
end