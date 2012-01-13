#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require 'rubyperf'
require 'cgi'

module Perf
  class ReportFormatHtml < ReportFormat

    PERCENT_FORMAT            = "%.3f"
    INDENT = "&nbsp;"*3

    def format_header(v)
      "<table class='rubyperf_report_format_html_table'><tr><th>#{v[:title]}</th><th>%</th><th>count</th><th>user</th><th>system</th><th>total</th><th>real</th></tr>"
    end

    def format_measure(v)
       percent= v[:percent].is_a?(String) ? v[:percent] : (PERCENT_FORMAT%v[:percent])
      "<tr><td>#{v[:title]}</td><td>#{percent}</td><td>#{v[:count]}</td><td>#{v[:time].utime}</td><td>#{v[:time].stime}</td><td>#{v[:time].total}</td><td>#{v[:time].real}</td></td>"
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
