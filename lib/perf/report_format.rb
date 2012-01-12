#
# Perf::ReportFormat is the base class for all the standard formatting options for a Perf::Meter
# For each measure it calculates its percentage vale compared to the containing block.
#

module Perf
  class ReportFormat

    MIN_TOTAL_TIME = 1.0e-10

    # Format takes a Perf::Meter plus a hash of options and converts it into a header, followed by a series
    # of entries in a hash format that can be easily converted in any other format such as Text, HTML, XML, etc.

    def format(perf,options={})
      options[:max_count_len] ||= 6
      rep=[]
      percents={}

      max_count=options[:max_count_len]
      max_title=0
      keys_in_order=perf.measurements.keys.sort
      total = Benchmark::Tms.new

      #pos = 0
      #old_depth=nil
      #keys_in_orderkeys_in_order.clone.each do |what|
      #  m=perf.measurements[what]
      #  depth = what.split("\\").size-1
      #  if old_depth && old_depth>depth
      #    keys_in_order.insert(pos,what+"\REMAINING")
      #  end
      #  old_depth=depth
      #  pos+=1
      #end

      perf.measurements.each_pair do |what,m|
        title_len=format_title(what,options).length
        path = what.split("\\")

        max_title = title_len             if title_len>max_title
        max_count = m[:count].to_s.length if m[:count].to_s.length>max_count

        total += m[:time] if path.size==3    # This calculates the max of the level-1 entries needed for the root entry.
      end

      totals=[total.real]
      depth=1
      keys_in_order.each do |what|
        m=perf.measurements[what]
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
        totals[totals.size-1] = MIN_TOTAL_TIME if totals[totals.size-1]<MIN_TOTAL_TIME
        percents[what]=(m[:time].real*100.0)/totals[totals.size-2]
      end

      # Header
      rep << format_header(:title      => "measure path", :max_title  => max_title,
                           :percent    => "percent",
                           :count      => "count",        :max_count  => max_count,
                           :time       => Benchmark::Tms::CAPTION,
                           :options    => options)

      # Root

      rep << format_root(:title      => "\\",               :max_title  => max_title,
                         :percent    => 100,
                         :count      => 1,                  :max_count  => max_count,
                         :time       => total,
                         :options    => options)

      # Split of keys
      keys_in_order.each do |what|
        m=perf.measurements[what]
        title = format_title(what,options)
        rep << format_line(:title      => title,              :max_title  => max_title,
                           :percent    => percents[what]||0.0,
                           :count      => m[:count],          :max_count  => max_count,
                           :time       => m[:time],
                           :options    => options)
      end

      rep
    end

    def format_header(v)
      format_line(v)
    end

    def format_root(v)
      format_line(v)
    end

    def format_line(v)
      v
    end

    def format_title(what,options)
      what
    end

  end
end