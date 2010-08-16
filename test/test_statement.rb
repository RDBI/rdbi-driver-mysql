require 'helper'

class TestStatement < Test::Unit::TestCase
  def setup
    @dbh = connect
  end

  def teardown
    @dbh.disconnect if @dbh and @dbh.connected?
  end

  def test_01_statement_creation
    sth = @dbh.prepare("create table `test` (id integer)")
    assert(sth)
    assert_equal(sth.query, "create table `test` (id integer)")
    sth.finish
  end
end
