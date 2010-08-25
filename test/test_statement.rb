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

  def test_03_first_and_last
    dbh.execute("insert into integer_test (id) values (?)", 1)

    sth = dbh.prepare("select * from integer_test")
    res = sth.execute

    assert_raises(RDBI::Cursor::NotRewindableError) do
      res.fetch(:first)
    end

    assert_raises(RDBI::Cursor::NotRewindableError) do
      res.fetch(:last)
    end

    sth.rewindable_result = true
    res = sth.execute

    assert_equal([1], res.fetch(:first))
    assert_equal([1], res.fetch(:last))

    sth.finish
  end
end
