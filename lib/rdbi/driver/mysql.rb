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
  # XXX basically taken verbatim from DBI. someone kill me now.
  TYPE_MAP = { }

  ::Mysql::Field.constants.grep(/^TYPE_/).each do |const|
    mysql_type = Mysql::Field.const_get(const)  # numeric type code
    TYPE_MAP[mysql_type] =
      case const.to_s
      when 'TYPE_TINY', 'TYPE_CHAR'
        # XXX gonna break. design fix.
        'tinyint'
      when 'TYPE_SHORT'
        'smallint'
      when 'TYPE_INT24'
        'mediumint'
      when 'TYPE_LONG'
        'integer'
      when 'TYPE_LONGLONG'
        'bigint'
      when 'TYPE_FLOAT'
        'float'
      when 'TYPE_DOUBLE'
        'double'
      when 'TYPE_VAR_STRING', 'TYPE_STRING'
        'varchar'
      when 'TYPE_DATE'
        'date'
      when 'TYPE_TIME'
        'time'
      when 'TYPE_DATETIME', 'TYPE_TIMESTAMP'
        'datetime'
      when 'TYPE_TINY_BLOB'
        'tinyblob'
      when 'TYPE_MEDIUM_BLOB'
        'mediumblob'
      when 'TYPE_LONG_BLOB'
        'longblob'
      when 'TYPE_GEOMETRY'
        'blob'
      when 'TYPE_YEAR',
          'TYPE_DECIMAL',
          'TYPE_BLOB',
          'TYPE_ENUM',
          'TYPE_SET',
          'TYPE_SET',
          'TYPE_BIT',
          'TYPE_NULL'
        const.to_s.sub(/^TYPE_/, '').downcase
      else
        'unknown'
      end
  end

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

      ep = Epoxy.new(query)
      @index_map = ep.indexed_binds

      # FIXME straight c'n'p from postgres, not sure it's needed.
      query = ep.quote(@index_map.compact.inject({}) { |x,y| x.merge({ y => nil }) }) { |x| '?' }

      @my_query = dbh.my_conn.prepare(query)
      # FIXME type maps
      @output_type_map = RDBI::Type.create_type_hash( RDBI::Type::Out )
    end

    def new_execution(*binds)
      # FIXME move to RDBI::Util or something.
      hashes, binds = binds.partition { |x| x.kind_of?(Hash) }
      hash = hashes.inject({}) { |x, y| x.merge(y) }
      hash.keys.each do |key| 
        if index = @index_map.index(key)
          binds.insert(index, hash[key])
        end
      end

      res = @my_query.execute(*binds)


      ary     = []

      # FIXME cursor driver needs to exist.
      res.num_rows.times { ary.push(res.fetch) }

      columns = []

      unless ary.empty? 
        columns = res.result_metadata.fetch_fields.collect do |col|
          RDBI::Column.new(
            col.name.to_sym,
            TYPE_MAP[col.type],
            TYPE_MAP[col.type].to_sym,
            col.length,
            col.decimals,
            !col.is_not_null?
          )
        end
      end

      affected = res.affected_rows
      schema = RDBI::Schema.new columns
      res.free_result
      [ ary, schema, @output_type_map, affected ]
    end

    def finish
      @my_query.close
      super
    end
  end
end
