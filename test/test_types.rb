require 'helper'

class TestTypes < Test::Unit::TestCase
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
end
