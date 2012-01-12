require "benchmark"
#
# Module user to measure the speed of a block of code or an expression

module Perf
  class Meter

    PATH_MEASURES  = '\blocks'
    PATH_METHODS   = '\methods'

    attr_accessor :measurements
    attr_accessor :current_stack

    #
    #
    #

    def initialize
      @measurements      = {}
      @current_stack     = []
      @instance_methods  = []
    end

    def get_measurement(path)
      @measurements[path] ||= {:count      => 0,
                               :time       => Benchmark::Tms.new,
                               :overhead   => Benchmark::Tms.new,
                               :measuring  => false}
    end

    def measure(what,&code)
      path="#{PATH_MEASURES}\\#{get_current_path}"
      @current_stack.push what
      res=measure_full_path(PATH_MEASURES) do
        measure_full_path("#{path}#{what}",&code)
      end
      @current_stack.pop
      res
    end

    #
    # Measures the time taken to execute the expression, and adds to "what_to_count = expression_result"  
    #
    def measure_result(what,&code)
      res=measure(what,&code)
      merge_measures(what,"#{what} = \"#{res.to_s}\"")
      res
    end

    def status
      @measurements.keys.sort.each do |what|
        puts what.to_s
      end
    end

    def measure_instance_method(klass,method_name)
      unless @instance_methods.find{|x| x[:klass]==klass && x[:method]==method_name}
        klass_path="#{PATH_METHODS}\\#{klass}"
        m=get_measurement("#{klass_path}\\#{method_name}")
        @instance_methods << {:klass=>klass,:method=>method_name,:perf=>m}
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

    def restore_instance_method(klass,method_name)
      if (idx=@instance_methods.find_index{|x| x[:klass]==klass && x[:method]==method_name})
        klass.send(:remove_method,method_name)
        klass.send(:alias_method, method_name, "old_#{method_name}")
        klass.send(:remove_method,"old_#{method_name}")
        @instance_methods.delete(idx)
      end
    end

    def measure_class_method(klass,method_name)
    end

    def measure_method(klass,method_name)
    end

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

  end
end
