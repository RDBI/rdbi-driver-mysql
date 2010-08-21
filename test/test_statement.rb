require 'helper'

class TestStatement < Test::Unit::TestCase
  def test_01_statement_creation_and_finish
    sth = dbh.prepare("create table `test` (id integer)")
    assert(sth)
    assert(!sth.finished?)
    assert_equal(sth.query, "create table `test` (id integer)")
    sth.finish
    assert(sth.finished?)
  end

  def test_02_statement_execution
    dbh.execute("drop table `test`") rescue nil
    dbh.execute("create table `test` (id integer)")
    sth = dbh.prepare("insert into test (id) values (?)")
    assert(sth)
    assert_equal(sth.query, "insert into test (id) values (?)")
    sth.execute(1)
    # FIXME affected rows
    sth.finish
    assert_equal([[1]], dbh.execute("select * from test").fetch(:all))
  end
end
