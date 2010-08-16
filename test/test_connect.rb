require 'helper'

class TestConnect < Test::Unit::TestCase
  def test_01_connect
    dbh = connect
    assert(dbh)
    assert(dbh.connected?)
    assert(dbh.database_name)
    # FIXME test value of dbname
  end

  def test_02_connect_exceptions
    e_database = ArgumentError.new("database name not provided")
    e_username = ArgumentError.new("username not provided")
    e_connect  = ArgumentError.new("either :host, :hostname, :socket, or :sock must be provided as a connection argument")

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
    assert_raises(e_database) { RDBI.connect(:MySQL, args) }

    args = base_args.dup
    args.delete(:username)
    assert_raises(e_username) { RDBI.connect(:MySQL, args) }
    
    args = base_args.dup
    args.delete(:host)
    args.delete(:hostname)
    args.delete(:sock)
    args.delete(:socket)
    assert_raises(e_connect) { RDBI.connect(:MySQL, args) }
  end
end
