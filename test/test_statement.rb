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
    sth = dbh.prepare("insert into integer_test (id) values (?)")
    assert(sth)
    assert_equal(sth.query, "insert into integer_test (id) values (?)")
    sth.execute(1)
    # FIXME affected rows
    sth.finish

    dbh.execute("select * from integer_test") do |res|
      assert_equal([[1]], res.fetch(:all))
    end
  end

  def test_03_rewindables

    dbh.execute("select * from integer_test") do |res|
      assert(res.empty?)
    end

    sth = dbh.prepare("insert into integer_test (id) values (?)")
    sth.execute(1)
    sth.execute(2)
    sth.finish

    sth = dbh.prepare("select * from integer_test")
    res = sth.execute

    assert_equal([1], res.fetch(:first))
    assert_equal([2], res.fetch(:last))
    assert_equal([[1], [2]], res.fetch(:rest))
    assert_equal([], res.fetch(:rest))

    res.rewind
    
    assert_equal([[1], [2]], res.fetch(:rest))

    sth.finish
  end
end
