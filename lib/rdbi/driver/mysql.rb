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
      raise ArgumentError, "username not provided"      unless username

      @my_conn = if args[:host] || args[:hostname]
                   Mysql.connect(
                     args[:host] || args[:hostname], 
                     username, 
                     password, 
                     self.database_name, 
                     args[:port]
                   )
                 elsif args[:sock] || args[:socket]
                   Mysql.connect(
                     nil, 
                     username, 
                     password, 
                     self.database_name, 
                     nil, 
                     args[:sock] || args[:socket]
                   )
                 else
                   raise ArgumentError, "either :host, :hostname, :socket, or :sock must be provided as a connection argument"
                 end
      # FIXME quoter
    end

    def disconnect
      @my_conn.close
      super
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

    def new_statement(query)
      Statement.new(query, self)
    end

    def table_schema(table_name)
    end

    def schema
    end
  end
  
  class Statement < RDBI::Statement
    extend MethLab

    attr_reader :my_query

    def initialize(query, dbh)
      super(query, dbh)
      @my_query = dbh.my_conn.prepare(query)

      # FIXME type maps
      @output_type_map = RDBI::Type.create_type_hash( RDBI::Type::Out )
    end

    def new_execution(*binds)
    end

    def finish
      @my_query.close
      super
    end
  end
end
