#
# rubyperf - Copyright (C) 2012 By Lorenzo Pasqualis - DreamBox Learning, Inc
#
# A gem to measure execution time of blocks of code, methods and expressions.
# It generates detailed reports in various formats showing the nested structure of the measures.
#
# It is designed to give tools to drill in the performance of hot code and identify bottlenecks.
#
# Currently available output formats for the report: text, html.
#
# Example of use:
#
#        m=Perf::Meter.new
#        m.measure(:string_operations) do
#          m.measure(:ciao) do
#            1000.times do; "CIAO"*100; end
#          end
#        end
#        m.measure(:string_operations) do
#          m.measure(:help) do
#            1000.times do; "HELP"*100; end
#          end
#        end
#        m.measure(:emtpy_loop) do
#          50000.times do; end;
#        end
#        m.measure(:rough_overhead_x10000) do
#          1000.times do
#            m.measure(:block_1) do
#              m.measure(:block_1_1) do
#              end
#              m.measure(:block_1_2) do
#                m.measure(:block_1_2_1) do
#                end
#                m.measure(:block_1_2_2) do
#                end
#                m.measure(:block_1_2_3) do
#                  m.measure_result(:bool_exp_1_2_3) { false }
#                  m.measure_result(:bool_exp_1_2_3) { true }
#                end
#              end
#            end
#          end
#        end
#
#        m.measure(:sleep1) do
#          m.measure(:sleep1_1) do
#            sleep(0.01)
#          end
#          m.measure(:sleep_1_2) do
#            sleep(0.02)
#          end
#          m.measure(:sleep_1_3) do
#            sleep(0.03)
#          end
#        end
#        m.measure(:empty) do
#        end
#        m.measure_result("test") { sleep(1) }
#        m.measure_result("test") { false }
#        m.measure_result("test") { false }
#
#        m.method_meters(Array,[:sort,:reverse],[:new]) do
#          Array.new(1000000,"abc").reverse.sort
#        end
#
#        puts m.report_simple
#
#  Outputs the following report.
#
#  Note: the percentage in each line is calculated on the real time of the containing block. For example in the example
#        block_1_1 takes 0.503% of the real time of block_1
#        block_1_2 takes 77.414% of the real time of block
#
#  measure path                                   : percent%  count       user     system      total        real
#
#  \blocks                                        : 100.000%   8014   1.040000   0.060000   1.100000 (  2.167488)
#      \empty                                     :   0.000%      1   0.000000   0.000000   0.000000 (  0.000005)
#      \emtpy_loop                                :   0.130%      1   0.010000   0.000000   0.010000 (  0.002825)
#      \rough_overhead_x10000                     :  49.354%      1   1.000000   0.060000   1.060000 (  1.069733)
#          \block_1                               :  92.013%   1000   0.890000   0.050000   0.940000 (  0.984297)
#              \block_1_1                         :   0.503%   1000   0.020000   0.000000   0.020000 (  0.004951)
#              \block_1_2                         :  77.414%   1000   0.670000   0.040000   0.710000 (  0.761979)
#                  \block_1_2_1                   :   0.640%   1000   0.000000   0.010000   0.010000 (  0.004880)
#                  \block_1_2_2                   :   0.644%   1000   0.010000   0.000000   0.010000 (  0.004904)
#                  \block_1_2_3                   :  48.027%   1000   0.370000   0.020000   0.390000 (  0.365958)
#                      \bool_exp_1_2_3 = "false"  :   1.354%   1000   0.000000   0.000000   0.000000 (  0.004956)
#                      \bool_exp_1_2_3 = "true"   :   1.369%   1000   0.020000   0.000000   0.020000 (  0.005012)
#      \sleep1                                    :   2.868%      1   0.000000   0.000000   0.000000 (  0.062157)
#          \sleep1_1                              :  17.808%      1   0.000000   0.000000   0.000000 (  0.011069)
#          \sleep_1_2                             :  32.524%      1   0.000000   0.000000   0.000000 (  0.020216)
#          \sleep_1_3                             :  49.090%      1   0.000000   0.000000   0.000000 (  0.030513)
#      \string_operations                         :   1.468%      2   0.030000   0.000000   0.030000 (  0.031817)
#          \ciao                                  :  95.276%      1   0.030000   0.000000   0.030000 (  0.030314)
#          \help                                  :   4.111%      1   0.000000   0.000000   0.000000 (  0.001308)
#      \test = "1"                                :  46.160%      1   0.000000   0.000000   0.000000 (  1.000502)
#      \test = "false"                            :   0.000%      2   0.000000   0.000000   0.000000 (  0.000008)
#  \methods                                       : 100.000%      3   0.140000   0.010000   0.150000 (  0.154880)
#      \#<Class:Array>                            :  21.416%      1   0.030000   0.010000   0.040000 (  0.033169)
#          \new                                   :  99.907%      1   0.030000   0.010000   0.040000 (  0.033138)
#      \Array                                     :  78.489%      2   0.110000   0.000000   0.110000 (  0.121563)
#          \reverse                               :  38.671%      1   0.040000   0.000000   0.040000 (  0.047010)
#          \sort                                  :  61.287%      1   0.070000   0.000000   0.070000 (  0.074502)
#

require 'perf/meter'
require 'perf/meter_factory'
require 'perf/no_op_meter'
require 'perf/report_format'
require 'perf/report_format_simple'
require 'perf/report_format_html'