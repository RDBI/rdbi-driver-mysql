require 'helper'

class TestTypes < Test::Unit::TestCase

  def setup
    super
    dbh.rewindable_result = true
  end

  def test_01_booleans
    dbh.cast_booleans = true
    res = dbh.execute( "SELECT true" )
    assert_equal true, res.fetch(:first)[0]

    res = dbh.execute( "SELECT false" )
    assert_equal false, res.fetch(:first)[0]

    dbh.cast_booleans = false
    res = dbh.execute( "SELECT true" )
    assert_equal 1, res.fetch(:first)[0]
    
    res = dbh.execute( "SELECT false" )
    assert_equal 0, res.fetch(:first)[0]

    dbh.execute("insert into boolean_test (id, item) values (?, ?)", 0, true);
    dbh.execute("insert into boolean_test (id, item) values (?, ?)", 1, false);

    dbh.cast_booleans = true
    row = dbh.execute("select id, item from boolean_test where id=?", 0).fetch(:first)
    assert_equal(0, row[0])
    assert_equal(true, row[1])
    
    row = dbh.execute("select id, item from boolean_test where id=?", 1).fetch(:first)
    assert_equal(1, row[0])
    assert_equal(false, row[1])

    dbh.cast_booleans = false
    row = dbh.execute("select id, item from boolean_test where id=?", 0).fetch(:first)
    assert_equal(0, row[0])
    assert_equal(1, row[1])
    
    row = dbh.execute("select id, item from boolean_test where id=?", 1).fetch(:first)
    assert_equal(1, row[0])
    assert_equal(0, row[1])
  end

  def test_02_general
    dbh.execute( "insert into foo (bar) values (?)", 1 )

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

  def test_03_datetime
    dt = DateTime.now
    dbh.execute("insert into datetime_test (item) values (?)", dt)
    row = dbh.execute("select item from datetime_test limit 1").fetch(:first)
    assert_equal(dt.to_s, row[0].to_s) 
  end
end
