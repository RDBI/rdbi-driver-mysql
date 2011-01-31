require 'helper'

class TestConnect < Test::Unit::TestCase
  def test_01_connect
    dbh = connect
    assert(dbh)
    assert(dbh.connected?)
    assert(dbh.database_name)

    assert_equal(dbh.database_name, role[:database])
  end

  def test_02_connect_exceptions
    base_args = {
      :host     => "localhost",
      :hostname => "localhost",
      :port     => 3306,
      :username => "foreal",
      :password => "notreally",
      :database => "foobar",
      :sock     => "/tmp/shit",
      :socket   => "/tmp/shit",
    }

    args = base_args.dup
    args.delete(:database)
    assert_raises(ArgumentError) { RDBI.connect(:MySQL, args) }

    args = base_args.dup
    args.delete(:username)
    assert_raises(ArgumentError) { RDBI.connect(:MySQL, args) }
    
    args = base_args.dup
    args.delete(:host)
    args.delete(:hostname)
    args.delete(:sock)
    args.delete(:socket)
    assert_raises(ArgumentError) { RDBI.connect(:MySQL, args) }
  end

  def test_03_disconnection
    dbh = connect
    assert(dbh)
    assert(dbh.connected?)
    dbh.disconnect
    assert(!dbh.connected?)

    assert_raises(Mysql::Error) { dbh.instance_variable_get(:@my_conn).ping }
  end
end
