require "benchmark"

module Perf

  #
  # Measures the runtime execution speed of a block of code, expression or entire methods.
  #
  # TODO:
  #
  #  * Eliminate the overhead of the perf meter operations from the computation of times.
  #  * Add an API to instrument all methods of a class in one bang.
  #
  # HISTORY:
  #
  #  * Jan 2012 | 1.0.0 | first public version
  #

  class Meter

    PATH_MEASURES  = '\blocks'
    PATH_METHODS   = '\methods'

    METHOD_TYPE_INSTANCE = :instance
    METHOD_TYPE_CLASS    = :class

    attr_accessor :measurements
    attr_accessor :current_stack

    def initialize
      @measurements             = {}
      @current_stack            = []
      @instrumented_methods     = {:instance=>[],:class=>[]}
      @class_methods            = []
    end

    # Takes a description and a code block and measures the performance of the block.
    # It returns the value retuend by the block
    #
    # ==== Attributes
    #
    # * +what+ - The title that will identify of the block
    # * +code+ - Block of code to measure
    #
    # ==== Examples
    #
    # Measures the time taken by the code in the block
    #
    #    perf = Perf::Meter.new
    #    perf.measure(:func) do
    #       some code here
    #    end
    #
    # Measure the time taken to  compute "some_expression"
    #
    #  if perf.measure(:some_expression) { some_expression }
    #    ...
    #  end
    #
    # Measure a bunch of things, and divides the measures in sub blocks that get measures separately
    #
    #  perf.measure(:bunch_of_stuff) do
    #     perf.measure(:thing1)  do
    #       ...
    #     end
    #     perf.measure(:thing2) do
    #        perf.measure(:thing2_part1) do
    #          ...
    #        end
    #        perf.measure(:thing2_part2) do
    #          ...
    #        end
    #     end
    #  end
    #

    def measure(what,&code)
      path="#{PATH_MEASURES}\\#{get_current_path}"
      @current_stack.push what
      res=measure_full_path(PATH_MEASURES) do
        measure_full_path("#{path}#{what}",&code)
      end
      @current_stack.pop
      res
    end

    # Takes a description and an expression returning a value and measures the performance of the expression storing the
    # result by returned value. Should be used only for expressions that can return only a small discrete number of unique
    # values, such a flag for example.
    #
    # It returns the value returned by the block
    #
    # ==== Attributes
    #
    # * +what+ - The title that will identify of the block
    # * +code+ - Block of code to measure
    #
    # ==== Examples
    #
    # Measures the time take to compute the existence of user xyz and will give you stats for the case in which the
    # result is true and false.
    #
    #    perf = Perf::Meter.new
    #    if perf.measure_result(:long_epression) { User.find(xyz).nil? }
    #    end
    #

    def measure_result(what,&code)
      res=measure(what,&code)
      merge_measures(what,"#{what} = \"#{res.to_s}\"")
      res
    end

    # Puts a wrapper around instance methods of a specific class to measure their performance
    # Remember to use restore_instance_method when you are done, otherwise the method will stay instrumented.
    #
    # Use sparingly!
    #
    # ==== Attributes
    #
    # * +klass+ - The Class containing the instance method that you want to measure
    # * +method_name+ - The name of the method that you want to measure
    #
    # ==== Examples
    #
    # Instruments the class find so that the execution of the method "find" will be measures every time that is used.
    #
    #    perf = Perf::Meter.new
    #    perf.measure_instance_method(User,:find)
    #    ..
    #
    # Removes the instrumentation (important!)
    #
    #    perf.restore_instance_method(User,:find)
    #
    # Removes all instrumentation from class User
    #
    #    perf.restore_all_instance_methods(User)
    #

    def measure_instance_method(klass,method_name)
      measure_method_by_type(klass,method_name,METHOD_TYPE_INSTANCE)
    end

    # Removes the instrumentation of a instance method in a given class.
    # See measure_instance_method for more information.

    def restore_instance_method(klass,method_name)
      restore_method_by_type(klass,method_name,METHOD_TYPE_INSTANCE)
    end

    # Removes all instrumentation of instance methods in a given class.
    # See measure_instance_method for more information.

    def restore_all_instance_methods(klass)
      restore_all_methods_by_type(klass,METHOD_TYPE_INSTANCE)
    end

    # Puts a wrapper around class methods of a specific class to measure their performance
    # Remember to use restore_class_method when you are done, otherwise the class method will stay instrumented.
    #
    # Use sparingly!
    #
    # ==== Attributes
    #
    # * +klass+ - The Class containing the instance method that you want to measure
    # * +method_name+ - The name of the class method that you want to measure
    #
    # ==== Examples
    #
    # Instruments the class find so that the execution of the class method "static_method" will be measures every time that is used.
    #
    #    perf = Perf::Meter.new
    #    perf.measure_class_method(SomeClass,:static_method)
    #    ..
    #
    # Removes the instrumentation (important!)
    #
    #    perf.restore_class_method(SomeClass,:static_method)
    #
    # Removes all instrumentation from class SomeClass
    #
    #    perf.restore_all_class_methods(SomeClass)
    #

    def measure_class_method(klass,method_name)
      measure_method_by_type(class << klass; self end,method_name,METHOD_TYPE_CLASS)
    end

    # Removes the instrumentation of a class method in a given class.
    # See measure_class_method for more information.

    def restore_class_method(klass,method_name)
      restore_method_by_type(class << klass; self end,method_name,METHOD_TYPE_INSTANCE)
    end

    # Removes the instrumentation of all class methods in a given class.
    # See measure_class_method for more information.

    def restore_all_class_methods(klass)
      restore_all_methods_by_type(class << klass; self end,METHOD_TYPE_INSTANCE)
    end

    # Removes all instrumentation of class methods and instance methods in a given class.
    # See measure_class_method for more information.

    def restore_all_methods(klass)
      restore_all_instance_methods(klass)
      restore_all_class_methods(klass)
    end

    # Measures a block of code given a full path. Should not be called directly unless you know what you are doing.

    def measure_full_path(path,&code)
      m=get_measurement(path)
      m[:count] += 1
      if m[:measuring]
        res=yield
      else
        res=nil
        m[:measuring]  = true
        m[:time]      += Benchmark.measure { res=code.call }
        m[:measuring]  = false
      end
      res
    end

private

    def set_measurement(path,m)
      @measurements[path]=m
    end

    def get_current_path
      @current_stack.join("\\") + (!@current_stack.empty? ? "\\" : "")
    end

    def merge_measures(what_from,what_to)
      measurement_root = "#{PATH_MEASURES}\\#{get_current_path}"
      path_from        = "#{measurement_root}#{what_from}"
      path_to          = "#{measurement_root}#{what_to}"
      m_from = get_measurement(path_from)
      m_to   = get_measurement(path_to)
      m_to[:time]       +=  m_from[:time]
      m_to[:count]      +=  m_from[:count]
      m_to[:measuring]  ||= m_from[:measuring]
      clear_measurement(path_from)
    end

    def clear_measurement(path)
      @measurements.delete(path)
    end

    def get_measurement(path)
      @measurements[path] ||= {:count      => 0,
                               :time       => Benchmark::Tms.new,
                               :overhead   => Benchmark::Tms.new,
                               :measuring  => false}
    end

    def measure_method_by_type(klass,method_name,type)
      unless @instrumented_methods[type].find{|x| x[:klass]==klass && x[:method]==method_name}
        klass_path="#{PATH_METHODS}\\#{klass}"
        m=get_measurement("#{klass_path}\\#{method_name}")
        @instrumented_methods[type]<< {:klass=>klass,:method=>method_name,:perf=>m}
        perf=self
        klass.send(:alias_method, "old_#{method_name}",method_name)
        klass.send(:define_method,method_name) do |*args|
          res=nil
          t = perf.measure_full_path(PATH_METHODS) do
                perf.measure_full_path(klass_path) do
                  Benchmark.measure{ res=self.send("old_#{method_name}", *args) }
                end
              end
          m[:time]  += t
          m[:count] += 1
          res
        end
      end
    end

    # Removes the instrumentation of a instance method in a given class.
    # See measure_instance_method for more information.

    def restore_method_by_type(klass,method_name,type)
      if (idx=@instrumented_methods[type].find_index{|x| x[:klass]==klass && x[:method]==method_name})
        klass.send(:remove_method,method_name)
        klass.send(:alias_method, method_name, "old_#{method_name}")
        klass.send(:remove_method,"old_#{method_name}")
        @instrumented_methods[type].delete_at(idx)
      end
    end

    # Removes all instrumentation of instance methods in a given class.
    # See measure_instance_method for more information.

    def restore_all_methods_by_type(klass,type)
      remove=[]
      @instrumented_methods[type].select {|x| x[:klass]==klass}.each do |im|
        klass.send(:remove_method,im[:method])
        klass.send(:alias_method, im[:method], "old_#{im[:method]}")
        klass.send(:remove_method,"old_#{im[:method]}")
        remove<<im
      end
      remove.each do |r|
        @instrumented_methods[type].delete(r)
      end
    end
  end
end