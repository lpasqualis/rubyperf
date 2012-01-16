#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

require 'rubyperf'

module Perf
  # Formats the report this way:
  #
  # measure path                : percent%  count       user     system      total        real
  # \                           : 100.000%      1   2.540000   0.030000   2.570000 (  4.602187)
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

  class ReportFormatSimple < ReportFormat

    DEFAULT_INDENT            = "    "
    PERCENT_FORMAT            = "%.3f"
    EXTRA_SPACES_AFTER_TITLE  = 2

    def format(perf,options={})
      options ||= {}
      options[:indent]        ||= DEFAULT_INDENT
      super perf,options
    end

    def format_measure(v)
      percent= v[:percent].is_a?(String) ? v[:percent] : (PERCENT_FORMAT%v[:percent])
      "#{v[:title].ljust(v[:max_title]+EXTRA_SPACES_AFTER_TITLE," ")}: #{percent.rjust(7," ")}% #{v[:accuracy].rjust(v[:max_accuracy]," ")} #{v[:count].to_s.rjust(v[:max_count]," ")} #{v[:time].to_s.gsub(/\n/,'')}\n"
    end

    def format_title(what,options)
      path=what.split("\\")
      "#{(path.size-2) ? options[:indent]*(path.size-2) : ""}\\#{path.last}"
    end

  end
end
