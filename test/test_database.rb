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
  end

  def test_04_transaction
    self.dbh = init_database

    dbh.transaction do
      assert dbh.in_transaction?
      5.times { dbh.execute( "insert into foo (bar) values (?)", 1 ) }
      dbh.rollback
      assert ! dbh.in_transaction?
    end

    assert ! dbh.in_transaction?

    assert_equal( [], dbh.execute("select * from foo").fetch(:all) )

    dbh.transaction do
      assert dbh.in_transaction?
      5.times { dbh.execute("insert into foo (bar) values (?)", 1) }
      assert_equal( [[1]] * 5, dbh.execute("select * from foo").fetch(:all) )
      dbh.commit
      assert ! dbh.in_transaction?
    end

    assert ! dbh.in_transaction?

    assert_equal( [[1]] * 5, dbh.execute("select * from foo").fetch(:all) )

    dbh.transaction do
      assert dbh.in_transaction?
      assert_raises( RDBI::TransactionError ) do
        dbh.transaction do
        end
      end
    end

    # Not in a transaction

    assert_raises( RDBI::TransactionError ) do
      dbh.rollback
    end

    assert_raises( RDBI::TransactionError ) do
      dbh.commit
    end
  end
  
  def test_05_preprocess_query
    self.dbh = init_database
    assert_equal(
      "insert into foo (bar) values (1)",
      dbh.preprocess_query( "insert into foo (bar) values (?)", 1 )
    )
  end

end
