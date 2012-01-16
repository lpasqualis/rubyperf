#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require 'rubyperf'
require 'cgi'

module Perf
  class ReportFormatHtml < ReportFormat

    PERCENT_FORMAT    = "%.2f"                   # default for :time_format
    TIME_FORMAT       = "%.7f"                   # default for :percent_format
    COUNT_FORMAT      = "%d"                     # default for :count_format
    INDENT            = "&nbsp;"*3               # default for :indent_string

    def initialize
      super
      @line=0
    end

    # Formats the report in HTML format and returns an array of strings containing the report.
    #
    # ==== Attributes
    #
    # * +perf+ - The Perf::Meter object to report
    # * +options+ - A hash of options as follows:
    #     :time_format => sprintf format of the time (see TIME_FORMAT for default)
    #     :percent_foramt => sprintf format of the percent (see PERCENT_FORMAT for default)
    #     :count_format   => sprintf format of the count (see COUNT_FORMAT for default)
    #     :indent_string  => what string to use to indent the path (see INDENT for default)
    #
    # ==== Example
    #
    # m=Perf::Meter.new
    # m.measure(:something) { something }
    # m.report_html()

    def format(perf,options={})
      options||={}
      @time_format     = options[:time_format]    || TIME_FORMAT
      @percent_format  = options[:percent_format] || PERCENT_FORMAT
      @count_format    = options[:count_format]   || COUNT_FORMAT
      @indent_string   = options[:indent_string]   || INDENT
      super
    end

    # Formats the header
    def format_header(v)
      "<table class='rubyperf_report'><tr>" \
        "<th class='title'>#{v[:title]}</th>" \
        "<th class='percent'>%</th>" \
        "<th class='count'>count</th>" \
        "<th class='user_time'>user</th>" \
        "<th class='system_time'>system</th>" \
        "<th class='total_time'>total</th>" \
        "<th class='real_time'>real</th>" \
      "</tr>"
    end

    # Formats the measure
    def format_measure(v)
      @line+=1
       percent= v[:percent].is_a?(String) ? v[:percent] : (@percent_format % v[:percent])
      "<tr class='#{@line % 2==0 ? "even_row" : "odd_row"}'>" \
        "<td class='title'>#{v[:title]}</td>" \
        "<td class='percent'>#{percent}</td>" \
        "<td class='count'>#{@count_format % v[:count]}</td>" \
        "<td class='user_time'>#{@time_format % v[:time].utime}</td>" \
        "<td class='system_time'>#{@time_format % v[:time].stime}</td>" \
        "<td class='total_time'>#{@time_format % v[:time].total}</td>" \
        "<td class='real_time'>#{@time_format % v[:time].real}</td>" \
      "</tr>"
    end

    def format_footer(v)
      "</table>"
    end

    def format_title(what,options)
      path=what.split("\\")
      "#{(path.size-2) ? @indent_string * (path.size-2) : ""}\\#{CGI.escapeHTML(path.last)}"
    end

  end
end
