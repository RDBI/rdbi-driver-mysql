require 'rubygems'
gem 'test-unit'
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rdbi/driver/mysql'
gem 'rdbi-dbrc'
require 'rdbi-dbrc'

class Test::Unit::TestCase

  attr_accessor :dbh

  SQL = [
    %q[drop table if exists test],
    %q[drop table if exists integer_test],
    %q[create table integer_test (id integer)],
    %q[drop table if exists foo],
    %q[create table foo (bar integer)],
    %q[drop table if exists datetime_test],
    %q[create table datetime_test (item datetime)],
    %q[drop table if exists boolean_test],
    %q[create table boolean_test (id integer, item boolean)]
  ]

  def init_database
    self.dbh = connect unless self.dbh and self.dbh.connected?

    SQL.each do |sql|
      dbh.execute(sql)
    end

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
