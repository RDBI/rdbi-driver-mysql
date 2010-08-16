require 'helper'

class TestConnect < Test::Unit::TestCase
  def test_01_connect
    dbh = connect
    assert(dbh)
    assert(dbh.connected?)
  end
end
