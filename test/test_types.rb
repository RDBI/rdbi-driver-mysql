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
  end
end
