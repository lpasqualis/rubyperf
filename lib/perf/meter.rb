#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require "benchmark"

module Perf

  #
  # Measures the runtime execution speed of a block of code, expression or entire methods.
  #

  class Meter

    PATH_MEASURES  = '\blocks'
    PATH_METHODS   = '\methods'

    METHOD_TYPE_INSTANCE = :instance
    METHOD_TYPE_CLASS    = :class

    attr_accessor :measurements
    attr_accessor :current_path

    def initialize
      @measurements             = {}      # A hash of Measure
      @current_path             = nil
      @instrumented_methods     = {METHOD_TYPE_INSTANCE=>[],METHOD_TYPE_CLASS=>[]}
      @class_methods            = []
      #@overhead = nil
      #@overhead = Benchmark.measure do
      #  measure(:a) {}
      #end
      #@overhead = nil
      @measurements             = {}      # A hash of Measure
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

    def measure(what,root_path=PATH_MEASURES,&code)
      current_path=@current_path
      if @current_path.nil?
        @current_path=root_path
        root=get_measurement(@current_path)
      else
        root=nil
      end
      @current_path+= "\\#{what}"
      res=nil
      begin
        m=get_measurement(@current_path)
        m.count     += 1
        m.measuring +=1
        if m.measuring>1
          res=code.call
        else
          t = Benchmark.measure { res=code.call }
          #t -= @overhead if @overhead
          #if t.total>=0 && t.real>=0
          m.time    += t
          root.time += t if root
          #end
        end
      ensure
        @current_path=current_path
        m.measuring-=1
      end
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
      res=measure(what,PATH_MEASURES,&code)
      merge_measures(what,"#{what} = \"#{res.to_s}\"")
      res
    end

    # Puts a wrapper around a set of methods of a specific class to measure their performance.
    # The set is provided with an array of iinstance methods, and one of class methods.
    #
    # The method defines the wrapper, yelds to the block, and then restores the instrumented class.
    # This ensures that the instrumented class is restored, and that the instrumentation occurs only in the context
    # of the block
    #
    # ==== Attributes
    #
    # * +klass+ - The Class containing the instance method that you want to measure
    # * +imethods+ - An array of instance methods that you want to measure
    # * +cmethods+ - An array of class methods that you want to measure
    #
    # ==== Examples
    #
    #    perf = Perf::Meter.new
    #    m.method_meters(PerfTestExample,[:test,:test_np],[:static_method]) do
    #      a=PerfTestExample.new
    #      a.test(1,2,3)
    #      a.test_np
    #      PerfTestExample.static_method
    #    end
    #
    # After this m contains measures for the executions of the instance methods test, test_np and the class
    # methods static_method
    #

    def method_meters(klass,imethods=[],cmethods=[])
      res=nil
      begin
        imethods.each {|m| measure_instance_method(klass,m) }
        cmethods.each {|m| measure_class_method(klass,m) }
        res=yield
      ensure
        imethods.each {|m| restore_instance_method(klass,m) }
        cmethods.each {|m| restore_class_method(klass,m) }
      end
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
      restore_method_by_type(class << klass; self end,method_name,METHOD_TYPE_CLASS)
    end

    # Removes the instrumentation of all class methods in a given class.
    # See measure_class_method for more information.

    def restore_all_class_methods(klass)
      restore_all_methods_by_type(class << klass; self end,METHOD_TYPE_CLASS)
    end

    # Removes all instrumentation of class methods and instance methods in a given class.
    # See measure_class_method for more information.

    def restore_all_methods(klass)
      restore_all_instance_methods(klass)
      restore_all_class_methods(klass)
    end

protected

    def set_measurement(path,m)
      @measurements[path]=m  if m.is_a? Perf::Measure
    end

    def get_current_path
      @current_stack.join("\\") + (!@current_stack.empty? ? "\\" : "")
    end

    def merge_measures(what_from,what_to)
      path_from        = "#{@current_path || PATH_MEASURES}\\#{what_from}"
      path_to          = "#{@current_path || PATH_MEASURES}\\#{what_to}"

      m_from = get_measurement(path_from)
      m_to   = get_measurement(path_to)

      m_to.merge(m_from)

      clear_measurement(path_from)
    end

    def clear_measurement(path)
      @measurements.delete(path)
    end

    def get_measurement(path)
      @measurements[path] ||= Perf::Measure.new(path)
    end

    def measure_method_by_type(klass,method_name,type)
      unless @instrumented_methods[type].find{|x| x[:klass]==klass && x[:method]==method_name}
        old_method_symbol="rubyperf_org_#{method_name}".to_sym
        @instrumented_methods[type] << { :klass=>klass, :method=>method_name, :org=>old_method_symbol }
        klass.send(:alias_method, old_method_symbol,method_name)
        perf=self
        klass.send(:define_method,method_name) do |*args|
          perf.measure("#{klass}.#{method_name}",PATH_METHODS) do
            self.send(old_method_symbol, *args)
          end
        end
      end
    end

    # Removes the instrumentation of a instance method in a given class.
    # See measure_instance_method for more information.

    def restore_method_by_type(klass,method_name,type)
      if (im=@instrumented_methods[type].find{|x| x[:klass]==klass && x[:method]==method_name})
        klass.send(:remove_method,im[:method])
        klass.send(:alias_method, im[:method], im[:org])
        klass.send(:remove_method,im[:org])
        @instrumented_methods[type].delete(im)
      end
    end

    # Removes all instrumentation of instance methods in a given class.
    # See measure_instance_method for more information.

    def restore_all_methods_by_type(klass,type)
      remove=[]
      @instrumented_methods[type].select {|x| x[:klass]==klass}.each do |im|
        klass.send(:remove_method,im[:method])
        klass.send(:alias_method, im[:method], im[:org])
        klass.send(:remove_method,im[:org])
        remove<<im
      end
      remove.each do |im|
        @instrumented_methods[type].delete(im)
      end
    end

    # You can generate a report using one of the built-in report formats with a simple syntax shortcut
    #
    #    m=Perf::Meter.new
    #    m.report_FORMAT
    #
    # Where FORMAT is the ending part of one of the ReportFormatFORMAT classes built in.
    #
    # ==== Examples
    #
    # m=Perf::Meter.new
    # m.measure(:something) {something}
    # puts m.report_html
    # puts m.report_simple
    #

    def method_missing(method_sym, *arguments, &block)
      if method_sym.to_s =~ /^report_(.*)$/
        klass=Object.const_get("Perf").const_get("ReportFormat#{$1.capitalize}")
        return klass.new.format(self) if klass
      end
      super
    end
  end
end
