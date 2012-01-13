#
# Copyright (c) 2012 Lorenzo Pasqualis - DreamBox Learning, Inc
# https://github.com/lpasqualis/rubyperf
#

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
end

