require "benchmark"
#
# Module user to measure the speed of a block of code or an expression

module Perf
  class Meter

    attr_accessor :measurements
    attr_accessor :current_stack

    #
    #
    #

    def initialize(x=nil)
      @measurements      = {}
      @current_stack     = ["\\"]
      @instance_methods  = []
    end

    def clear
      initialize
    end

    ##############################################################################################################

    def get_measurement(what)
      @measurements[what] ||= {:count      => 0,
                               :time       => Benchmark::Tms.new,
                               :measuring  => false}
    end

    #
    # Measures the time taken to execute the block, and adds to "what"
    #
    def measure(what,type=nil)
      res=nil
      what = "#{what}_#{type}".to_sym if (type)
      path="#{@current_stack.join("\\")}\\"
      @current_stack.push what
      what = "#{path}#{what}"
      m=get_measurement(what)
      m[:count] += 1
      if m[:measuring]
        res=yield
      else
        m[:measuring]  = true
        m[:time]      += Benchmark.measure { res=yield }
        m[:measuring]  = false
      end
      @current_stack.pop
      res
    end

    #
    # Measures the time taken to execute the expression, and adds to "what_to_count = expression_result"  
    #
    def count_value(what_to_count)
      res  = nil
      t    = Benchmark.measure { res=yield }
      path = "#{@current_stack.join("\\")}\\"
      what = "#{path}#{what_to_count.to_s} = \"#{res.to_s}\""
      m    = get_measurement(what)
      m[:time]  += t
      m[:count] += 1
      res
    end

    def status
      @measurements.keys.sort.each do |what|
        puts what.to_s
      end
    end

    def measure_instance_method(klass,method_name)
      m=get_measurement("\\#{klass.to_s}\\#{method_name}")
      unless @instance_methods.find{|x| x[:klass]==klass && x[:method]==method_name}
        @instance_methods << {:klass=>klass,:method=>method_name,:perf=>m}

        klass.send(:alias_method, "old_#{method_name}",method_name)
        klass.send(:define_method,method_name) do |*args|
          res=nil
          t = Benchmark.measure { res=self.send("old_#{method_name}", *args) }
          m[:time]  += t
          m[:count] += 1
          res
        end
      end
    end

    def measure_class_method(klass,method_name)
    end

    def measure_method(klass,method_name)
    end

  end
end
