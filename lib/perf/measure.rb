#
# Module user to measure the speed of a block of code or an expression
# The report is generated in this format:
#
#measure path                 : percent%  count       user     system      total        real
#\                            : 100.000%      1   2.540000   0.030000   2.570000 (  4.602187)
#    \emtpy_loop              :   0.042%      1   0.000000   0.000000   0.000000 (  0.001946)
#    \measure_overhead_x10000 :   5.893%      1   0.260000   0.010000   0.270000 (  0.271223)
#        \nothing1            :  90.286%   1000   0.250000   0.010000   0.260000 (  0.244876)
#            \blah2           :   2.685%   1000   0.010000   0.000000   0.010000 (  0.006574)
#            \nothing2        :  74.104%   1000   0.120000   0.010000   0.130000 (  0.181462)
#                \blah3       :   4.020%   1000   0.010000   0.000000   0.010000 (  0.007294)
#                \nothing3    :   3.679%   1000   0.070000   0.000000   0.070000 (  0.006676)
#                \zzzzblah3   :   3.716%   1000   0.000000   0.000000   0.000000 (  0.006744)
#    \something               :  11.144%      1   0.000000   0.000000   0.000000 (  0.512861)
#        \something1          :  39.077%      1   0.000000   0.000000   0.000000 (  0.200411)
#        \something2          :  60.864%      2   0.000000   0.000000   0.000000 (  0.312149)
#    \string_operations       :  20.097%      2   0.910000   0.000000   0.910000 (  0.924894)
#        \ciao1000            :  50.085%      1   0.460000   0.000000   0.460000 (  0.463233)
#        \help1000            :  49.893%      1   0.450000   0.000000   0.450000 (  0.461461)
#    \test = "1"              :  21.737%      1   0.000000   0.000000   0.000000 (  1.000368)
#    \test = "false"          :   0.000%      2   0.000000   0.000000   0.000000 (  0.000015)
#
#
# Where:
#
#    percent% : is the percentage of the real time of the real time of its containing path.
#               For example blah2 is 2.685% of the real time of nothing1.The sum of the percentages at the same depth
#               should always be < 100% (for example depth2 1 is 0.042+5.893+11.144+20.097+21.737 = 58.913). The rest
#               is unmeasured time spent.
#    count    : is the number of time the measure was taken. All the measures are the cumulative elapsed time for all
#               the measures. For example blah3 numbers refer to the cumulative time spent in 1000 execution of that block.
#   user      : User CPU time
#   system    : System CPU time
#   total     : user+system
#   real      : Real time
#

module Perf

  class Measure

    DEFAULT_INDENT="    "
    PERCENT_FORMAT="%.3f"

    #
    #
    #

    def initialize(logger = Logger.new(STDOUT))
      @m      = {}
      @stack  = []
      @logger = logger
    end

    def clear
      initialize
    end

    #############################################################################################################

    def self.singleton(key=:default,create_if_not_exists=true)
      @@dbl_perf_measure      ||= {}
      return ( @@dbl_perf_measure[key] ||= ( create_if_not_exists ? (Perf::Measure.new) : (Perf::NoopMeasure.new) ) )
    end

    def self.get_meter(key=:default)
      # We could call singleton(key,false) but for performance reasons we replicate the code
      @@dbl_perf_measure      ||= {}
      return ( @@dbl_perf_measure[key] ||= Perf::NoopMeasure.new )
    end

    def self.get_or_create_meter(key=:default)
      # We could call singleton(key,true) but for performance reasons we replicate the code
      @@dbl_perf_measure      ||= {}
      return ( @@dbl_perf_measure[key] ||= Perf::Measure.new )
    end

    def self.store_meter(meter,key=:default)
      @@dbl_perf_measure      ||= {}
      @@dbl_perf_measure[key] ||= meter
    end

    def self.clear_meter(key)
      @@dbl_perf_measure.delete(key) if @@dbl_perf_measure
    end

    #############################################################################################################

    def self.all_singletons
      return @@dbl_perf_measure || {}
    end

    def self.clear_all_singletons
      @@dbl_perf_measure=Hash.new
    end

    ##############################################################################################################

    def get_measure(what)
      @m[what] ||= {:count      => 0,
                    :time       => Benchmark::Tms.new,
                    :measuring  => false}
    end

    def get_current_path
      "#{@stack.join("\\")}\\"
    end
    #
    # Measures the time taken to execute the block, and adds to "what"
    #
    def measure(what,type=nil)
      res=nil
      what = "#{what}_#{type}".to_sym if (type)
      path=get_current_path
      @stack.push what
      what = "#{path}#{what}"
      m=get_measure(what)
      m[:count] += 1
      if m[:measuring]
        res=yield
      else
        m[:measuring]=true
        t = Benchmark.measure { res=yield }
        m[:time] += t
        m[:measuring] = false
      end
      @stack.pop
      res
    end

    #
    # Measures the time taken to execute the expression, and adds to "what_to_count = expression_result"  
    #
    def count_value(what_to_count)
      res=nil
      t = Benchmark.measure { res=yield }
      path=get_current_path
      what = "#{path}#{what_to_count.to_s} = \"#{res.to_s}\""
      m=get_measure(what)
      m[:time] += t
      m[:count] += 1
      res
    end

    #
    # Returns the report as an array of strings
    # Options are:
    #   :total=>true                 If you want to include a total
    #
    def report_arr(options={})
      options[:indent] ||= DEFAULT_INDENT
      rep=[]
      max_count=6
      max_title=0
      keys_in_order=@m.keys.sort
      total = Benchmark::Tms.new

      @m.each_pair do |what,m|
        path = what.split("\\")
        desc_len = (options[:indent].length*(path.size-2))+path.last.length+2

        max_title = desc_len              if desc_len>max_title
        max_count = m[:count].to_s.length if m[:count].to_s.length>max_count

        total += m[:time] if path.size==3
      end

      totals=[total.real]
      depth=1
      keys_in_order.each do |what|
        m=@m[what]
        path = what.split("\\")
        if path.size-1 != depth
          if path.size-1 > depth
            totals.push 0
          else
            totals.pop(depth-(path.size-1))
          end
          depth=path.size-1
        end
        totals[totals.size-1] = m[:time].real
        totals[totals.size-1] = 1.0e-10 if totals[totals.size-1]<1.0e-10
        # puts "path.size=#{path.size} depth=#{depth} totals=[#{totals.collect{|a| PERCENT_FORMAT%a}.join(",")}] #{what}"
        m[:percent]=(m[:time].real*100.0)/totals[totals.size-2]
      end

      # Header
      rep << format_line(:title      => "measure path", :max_title  => max_title,
                         :percent    => "percent",
                         :count      => "count",        :max_count  => max_count,
                         :time       => Benchmark::Tms::CAPTION)

      # Root

      rep << format_line(:title      => "\\",               :max_title  => max_title,
                         :percent    => 100,
                         :count      => 1,                  :max_count  => max_count,
                         :time       => total)

      # Split of keys
      keys_in_order.each do |what|
        m=@m[what]
        title = get_title_with_indent(what,options)
        rep << format_line(:title      => title,              :max_title  => max_title,
                           :percent    => m[:percent]||0,
                           :count      => m[:count],          :max_count  => max_count,
                           :time       => m[:time])
      end

      rep
    end

    def output(str,options={})
      if @logger
        @logger.info str
      else
        puts str
      end
    end

    def status
      @m.keys.sort.each do |what|
        puts what.to_s
      end
    end

    #
    # Outputs the report returned by report_arr
    #
    def report(options={})
      output ""
      report_arr(options).each do |r|
        output r
      end
      output ""
      true
    end

    private

    def format_line(v)
      percent= v[:percent].is_a?(String) ? v[:percent] : (PERCENT_FORMAT%v[:percent])
      "#{v[:title].ljust(v[:max_title]," ")}: #{percent.rjust(7," ")}% #{v[:count].to_s.rjust(v[:max_count]," ")} #{v[:time].to_s.gsub(/\n/,'')}\n"
    end

    def get_title_with_indent(what,options)
      path=what.split("\\")
      "#{(path.size>2) ? options[:indent]*(path.size-2) : ""}\\#{path.last}"
    end


    public

    ##################################################################################################################
    ##################################################################################################################

    class Example
      #
      # Example of usage:
      #
      def self.example
        m=Perf::Measure.new(nil)
        m.measure(:string_operations) do
          m.measure(:ciao1000) do
            10000.times do; "CIAO"*1000; end
          end
        end
        m.measure(:string_operations) do
          m.measure(:help1000) do
            10000.times do; "HELP"*1000; end
          end
        end
        m.measure(:emtpy_loop) do
          50000.times do; end;
        end
        m.measure(:measure_overhead_x10000) do
          1000.times do
            m.measure(:nothing1) do
              m.measure(:blah2) do
              end
              m.measure(:nothing2) do
                m.measure(:nothing3) do
                end
                m.measure(:blah3) do
                end
                m.measure(:zzzzblah3) do
                end
              end
            end
          end
        end

        m.measure(:something) do
          m.measure(:something1) do
            sleep(0.2)
          end
          m.measure(:something2) do
            sleep(0.3)
          end
          m.measure(:something2) do
            sleep(0.01)
          end
        end
        m.measure(:fast) do
        end
        m.count_value("test") { sleep(1) }
        m.count_value("test") { false }
        m.count_value("test") { false }
        puts "---- STATUS ----"
        m.status
        #return if true
        puts "---- REPORT-----"
        m.report
      end

    end
  end

end

