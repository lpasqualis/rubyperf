#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

module Perf

  #
  # Base class for all the standard formatting options for a Perf::Meter. Provies a simple interface to create
  # custom views of the performance report.
  #
  class ReportFormat

    MIN_TOTAL_TIME = 1.0e-10

    # Format takes a Perf::Meter plus a hash of options and converts it into a header, followed by a series
    # of entries in a hash format that can be easily converted in any other format such as Text, HTML, XML, etc.
    #
    # You call this method every time that you want to generate a report from a Perf::Meter object.
    #
    # ==== Options
    #
    # * +:max_count_len+  : Maximum expected length of a block/espresson/method count.
    #

    def format(perf,options={})
      options[:max_count_len] ||= 6
      rep=[]
      percents={}

      max_count=options[:max_count_len]
      max_title=0
      keys_in_order=perf.measurements.keys.sort
      total = Benchmark::Tms.new

      perf.measurements.each_pair do |what,m|
        title_len=format_title(what,options).length
        path = what.split("\\")

        max_title = title_len             if title_len>max_title
        max_count = m.count.to_s.length   if m.count.to_s.length>max_count

        total += m.time if path.size==2    # This calculates the max of the level-1 entries needed for the root entry.
      end

      totals=[total.real]
      depth=1
      keys_in_order.each do |what|
        m = perf.measurements[what]
        path = what.split("\\")
        if path.size-1 != depth
          if path.size-1 > depth
            totals.push 0
          else
            totals.pop(depth-(path.size-1))
          end
          depth=path.size-1
        end
        totals[totals.size-1] = m.time.real
        totals[totals.size-1] = MIN_TOTAL_TIME if totals[totals.size-1]<MIN_TOTAL_TIME
        percents[what]=(m.time.real*100.0)/totals[totals.size-2]
      end

      # Header
      rep << format_header(:title      => "measure path", :max_title  => max_title,
                           :percent    => "percent",
                           :count      => "count",        :max_count  => max_count,
                           :time       => Benchmark::Tms::CAPTION,
                           :options    => options)

      # Root

      # Split of keys
      keys_in_order.each do |what|
        m=perf.measurements[what]
        title = format_title(what,options)
        rep << format_measure(:title      => title,              :max_title  => max_title,
                              :percent    => percents[what]||0.0,
                              :count      => m.count,            :max_count  => max_count,
                              :time       => m.time,
                              :options    => options)
      end

      rep << format_footer(options)
      rep
    end

    # Override to format the output of a single measure. Returns the measure in whatever format the output needs to be.
    #
    # ==== Options
    #
    # * +v+  : Hash containing the following keys:
    #           +title+      : Title - or path - of the block/method/expression (\root\a\b\c\d\something))
    #           +max_title+  : Longest title in the report
    #           +percent+    : Percentage of time spent in this measure compared to the containing block.
    #           +count+      : How many times the block/method/exression was executed
    #           +time+       : Execution time expressed as a Benchmark::Tms value; For titles this is Benchmark::Tms::CAPTION
    #           +options+    : Formatting options, as passed by the framework or the user.
    #

    def format_measure(v)
      v
    end

    # Override to format the output of the header of the data.
    #
    # See format_measure

    def format_header(v)
      format_measure(v)
    end

    # Override to format the output of the header of the data.
    #
    # See format_measure

    def format_title(what,options)
      what
    end

    # Override to format the output of the footer of the data.
    #
    # See format_measure

    def format_footer(options)
      ""
    end

  end
end