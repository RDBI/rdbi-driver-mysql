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
    assert_equal(1, dbh.execute_modification( "insert into foo (bar) values (?)", 1 ))

    dbh.execute( "select * from foo" ) do |res|
      assert res
      assert_kind_of( RDBI::Result, res )
      assert_equal( [[1]], res.fetch(:all) )

      rows = res.as( :Struct ).fetch( :all )
      row = rows[ 0 ]
      assert_equal( 1, row.bar )
    end
  end

  def test_04_transaction
    self.dbh = init_database
    dbh.rewindable_result = false

    dbh.transaction do
      assert dbh.in_transaction?
      5.times { dbh.execute_modification( "insert into foo (bar) values (?)", 1 ) }
      dbh.rollback
      assert ! dbh.in_transaction?
    end

    assert ! dbh.in_transaction?

    assert_equal( [], dbh.execute("select * from foo").fetch(:all) )

    dbh.transaction do
      assert dbh.in_transaction?
      5.times { dbh.execute_modification("insert into foo (bar) values (?)", 1) }
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
  
  def test_06_schema
    self.dbh = init_database

    dbh.execute_modification( "insert into bar (foo, bar) values (?, ?)", "foo", 1 )
    res = dbh.execute( "select * from bar" )

    assert res
    assert res.schema
    assert_kind_of( RDBI::Schema, res.schema )
    assert res.schema.columns
    res.schema.columns.each { |x| assert_kind_of(RDBI::Column, x) }
    
  end
  
  def test_07_table_schema
    self.dbh = init_database
    assert_respond_to( dbh, :table_schema )
    
    assert(dbh.table_schema('pk_test').columns.find {|x| x.name == :id }.primary_key)
    assert(!dbh.table_schema('pk_test').columns.find {|x| x.name == :something_else }.primary_key)

    schema = dbh.table_schema( :foo )
    columns = schema.columns
    assert_equal columns.size, 1
    c = columns[ 0 ]
    assert_equal c.name, :bar
    assert_equal c.type, :int

    schema = dbh.table_schema( :bar )
    columns = schema.columns
    assert_equal columns.size, 2
    columns.each do |c|
      case c.name
      when :foo
        assert_equal c.type, :varchar
      when :bar
        assert_equal c.type, :int
      end
    end

    assert_nil dbh.table_schema( :non_existent )
  end
  
  def test_08_basic_schema
    self.dbh = init_database
    assert_respond_to( dbh, :schema )
    schema = dbh.schema.sort_by { |x| x.tables[0].to_s }

    tables = [ :bar, :boolean_test, :datetime_test, :foo, :integer_test, :pk_test ]
    columns = {
      :bar => { :foo => :varchar, :bar => :int },
      :foo => { :bar => :int },
      :integer_test => { :id => :int },
      :datetime_test => { :item => :datetime },
      :boolean_test => { :id => :int, :item => :tinyint },
      :pk_test => { :id => :int, :something_else => :varchar }
    }

    schema.each_with_index do |sch, x|
      assert_kind_of( RDBI::Schema, sch )
      assert_equal( sch.tables[0], tables[x] )

      sch.columns.each do |col|
        assert_kind_of( RDBI::Column, col )
        assert_equal( columns[ tables[x] ][ col.name ], col.type )
      end
    end
  end

  def test_09_quote
    self.dbh = init_database

    assert_equal(%q[1], dbh.quote(1))
    assert_equal(%q[0], dbh.quote(false))
    assert_equal(%q[1], dbh.quote(true))
    assert_equal(%q[NULL], dbh.quote(nil))
    assert_equal(%q['shit'], dbh.quote('shit'))
    assert_equal(%q['shit\\'t'], dbh.quote('shit\'t'))
  end
end
