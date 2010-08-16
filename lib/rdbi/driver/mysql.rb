require 'rdbi'
require 'epoxy'
require 'methlab'

gem 'mysql', '=~ 2.8.1'
require 'mysql'

class RDBI::Driver::MySQL < RDBI::Driver
  def initialize( *args )
    super( Database, *args )
  end
end

class RDBI::Driver::MySQL < RDBI::Driver
  class Database < RDBI::Database
    extend MethLab

    def initialize(*args)
    end

    def disconnect
    end

    def transaction(&block)
      super &block
    end

    def rollback
      super
    end

    def commit
      super
    end

    def new_statement
    end

    def table_schema(table_name)
    end

    def schema
    end
  end
  
  class Statement < RDBI::Statement
    extend MethLab

    def initialize(query, dbh)
    end

    def new_execution(*binds)
    end

    def finish
      super
    end
  end
end
