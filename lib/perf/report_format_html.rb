#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require 'rubyperf'
require 'cgi'

module Perf
  class ReportFormatHtml < ReportFormat

    PERCENT_FORMAT    = "%.3f"
    INDENT            = "&nbsp;"*3

    def initialize
      super
      @line=0
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
       percent= v[:percent].is_a?(String) ? v[:percent] : (PERCENT_FORMAT%v[:percent])
      "<tr class='#{@line % 2==0 ? "even_row" : "odd_row"}'>" \
        "<td class='title'>#{v[:title]}</td>" \
        "<td class='percent'>#{percent}</td>" \
        "<td class='count'>#{v[:count]}</td>" \
        "<td class='user_time'>#{v[:time].utime}</td>" \
        "<td class='system_time'>#{v[:time].stime}</td>" \
        "<td class='total_time'>#{v[:time].total}</td>" \
        "<td class='real_time'>#{v[:time].real}</td>" \
      "</tr>"
    end

    def format_footer(v)
      "</table>"
    end

    def format_title(what,options)
      path=what.split("\\")
      "#{(path.size-2) ? INDENT*(path.size-2) : ""}\\#{CGI.escapeHTML(path.last)}"
    end

  end
end
