class PerfTestExample
  def test(a,b,c)
    (0..100000).to_a.reverse.reverse.reverse # Do something heavy
  end

  def test_np
    (0..300000).to_a.reverse.reverse.reverse # Do something heavy
  end

  def self.static_method
    (0..300000).to_a.reverse.reverse.reverse # Do something heavy
  end

  def test_with_measure
    Perf::MeterFactory.get.measure(:test_with_measure_block) do
      test(1,2,3)
      PerfTestExample.static_method
    end
  end

  def test_with_measure_static
    Perf::MeterFactory.get.measure(:test_with_measure_block) do
      static_method
    end
  end

end

