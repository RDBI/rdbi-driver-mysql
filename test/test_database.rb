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
  
  def test_03_execute
    self.dbh = init_database
    res = dbh.execute( "insert into foo (bar) values (?)", 1 )
    assert res
    assert_kind_of( RDBI::Result, res )
    assert_equal( 1, res.affected_count )

    res = dbh.execute( "select * from foo" )
    assert res
    assert_kind_of( RDBI::Result, res )
    assert_equal( [[1]], res.fetch(:all) )

    rows = res.as( :Struct ).fetch( :all )
    row = rows[ 0 ]
    assert_equal( 1, row.bar )

    res = dbh.execute( "select count(*) from foo" )
    assert res
    assert_kind_of( RDBI::Result, res )
    assert_equal( [[1]], res.fetch(:all) )
    row = res.as( :Array ).fetch( :first )
    assert_equal 1, row[ 0 ]

    res = dbh.execute( "SELECT 5" )
    assert res
    assert_kind_of( RDBI::Result, res )
    row = res.as( :Array ).fetch( :first )
    assert_equal 5, row[ 0 ]

    time_str = DateTime.now.strftime( "%Y-%m-%d %H:%M:%S %z" )
    res = dbh.execute( "SELECT 5, 'hello', cast('#{time_str}' as datetime)" )
    assert res
    assert_kind_of( RDBI::Result, res )
    row = res.fetch( :all )[ 0 ]
    assert_equal 5, row[ 0 ]
    assert_equal 'hello', row[ 1 ]
    assert_equal DateTime.parse( time_str ), row[ 2 ]
  end
end
