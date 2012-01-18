require 'rubyperf'

module Perf

  # ReportFormatListOfMeasures is use for unit tests to list the measures taken and their count. It has no other
  # real life purpose.

  class ReportFormatListOfMeasures < ReportFormat

    def format(perf,options={})
      super.select{|x| x.length>0 }
    end

    def format_header(v)
      ""
    end

    def format_measure(v)
      "#{v[:title]},#{v[:count]}"
    end

    def format_footer(v)
      ""
    end

    def format_title(what,options)
      what
    end

  end
end
