require 'rdbi'
require 'epoxy'
require 'methlab'

gem 'mysql', '= 2.8.1'
require 'mysql'

class RDBI::Driver::MySQL < RDBI::Driver
  def initialize( *args )
    super( Database, *args )
  end
end

class RDBI::Driver::MySQL < RDBI::Driver
  class Database < RDBI::Database
    extend MethLab

    attr_reader :my_conn

    def initialize(*args)
      super(*args)

      args = args[0]

      self.database_name = args[:database] || args[:dbname] || args[:db]

      username = args[:username] || args[:user]
      password = args[:password] || args[:pass]

      # FIXME flags?

      raise ArgumentError, "database name not provided" unless self.database_name
      raise ArgumentError, "username not provided" unless username

      @my_conn = if args[:host] || args[:hostname]
                   Mysql.connect(args[:host] || args[:hostname], username, password, self.database_name, args[:port])
                 elsif args[:sock] || args[:socket]
                   Mysql.connect(nil, username, password, self.database_name, nil, args[:sock])
                 else
                   raise ArgumentError, "either :host, :hostname, :socket, or :sock must be provided as a connection argument"
                 end
      # FIXME quoter
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
