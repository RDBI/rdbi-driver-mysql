require 'helper'

class TestDatabase < Test::Unit::TestCase
  def test_01_connect
    assert dbh
    assert_kind_of( RDBI::Driver::MySQL::Database, dbh )
    assert_kind_of( RDBI::Database, dbh )
    assert_equal( dbh.database_name, role[:database] )
    dbh.disconnect
    assert ! dbh.connected?
  end

  def test_02_ping
    my_role = role.dup
    driver = my_role.delete(:driver)

    assert_kind_of(Numeric, dbh.ping)
    assert_kind_of(Numeric, RDBI.ping(driver, my_role))
    dbh.disconnect

    assert_raises(RDBI::DisconnectedError.new("not connected")) do
      dbh.ping
    end

    # XXX This should still work because it connects. Obviously, testing a
    # downed database is gonna be pretty hard.
    assert_kind_of(Numeric, RDBI.ping(driver, my_role))
  end
end