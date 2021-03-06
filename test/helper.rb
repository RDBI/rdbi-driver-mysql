require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rdbi/driver/mysql'
require 'rdbi-dbrc'

class Test::Unit::TestCase

  attr_accessor :dbh

  SQL = [
    %q[drop table if exists test],
    %q[drop table if exists integer_test],
    %q[create table integer_test (id integer) ENGINE=InnoDB],
    %q[drop table if exists foo],
    %q[create table foo (bar integer) ENGINE=InnoDB],
    %q[drop table if exists datetime_test],
    %q[create table datetime_test (item datetime) ENGINE=InnoDB],
    %q[drop table if exists boolean_test],
    %q[create table boolean_test (id integer, item boolean) ENGINE=InnoDB],
    %q[drop table if exists bar],
    %q[create table bar (foo varchar(255), bar integer) ENGINE=InnoDB],
    %q[drop table if exists pk_test],
    %q[create table pk_test (id integer primary key auto_increment, something_else varchar(255) not null) ENGINE=InnoDB],
  ]

  def init_database
    self.dbh = connect unless self.dbh and self.dbh.connected?

    SQL.each do |sql|
      dbh.execute(sql)
    end

    self.dbh.rewindable_result = false
    self.dbh
  end

  def connect
    RDBI::DBRC.connect(:mysql_test)
  end

  def role
    RDBI::DBRC.roles[:mysql_test]
  end

  def setup
    init_database
  end

  def teardown
    dbh.disconnect if dbh and dbh.connected?
  end
end
