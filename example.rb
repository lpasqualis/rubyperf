require 'rubyperf'

def example
    m=Perf::Meter.new
    m.measure(:string_operations) do
      m.measure(:ciao) do
        1000.times do; "CIAO"*100; end
      end
    end
    m.measure(:string_operations) do
      m.measure(:help) do
        1000.times do; "HELP"*100; end
      end
    end
    m.measure(:emtpy_loop) do
      50000.times do; end;
    end
    m.measure(:rough_overhead_x10000) do
      1000.times do
        m.measure(:block_1) do
          m.measure(:block_1_1) do
          end
          m.measure(:block_1_2) do
            m.measure(:block_1_2_1) do
            end
            m.measure(:block_1_2_2) do
            end
            m.measure(:block_1_2_3) do
              m.measure_result(:bool_exp_1_2_3) { false }
              m.measure_result(:bool_exp_1_2_3) { true }
            end
          end
        end
      end
    end

    m.measure(:sleep1) do
      m.measure(:sleep1_1) do
        sleep(0.01)
      end
      m.measure(:sleep_1_2) do
        sleep(0.02)
      end
      m.measure(:sleep_1_3) do
        sleep(0.03)
      end
    end
    m.measure(:empty) do
    end
    m.measure_result("test") { sleep(1) }
    m.measure_result("test") { false }
    m.measure_result("test") { false }

    m.method_meters(Array,[:sort,:reverse],[:new]) do
      Array.new(1000000,"abc").reverse.sort
    end

    puts m.report_simple
end