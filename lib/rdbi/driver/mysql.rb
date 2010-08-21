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
      when 'TYPE_DATE', 'TYPE_TIME', 'TYPE_DATETIME', 'TYPE_TIMESTAMP'
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
    attr_accessor :cast_booleans

    def initialize(*args)
      super(*args)

      args = args[0]

      self.database_name = args[:database] || args[:dbname] || args[:db]

      username = args[:username] || args[:user]
      password = args[:password] || args[:pass]

      # FIXME flags?

      raise ArgumentError, "database name not provided" unless self.database_name
      raise ArgumentError, "username not provided"      unless username

      @cast_booleans = args[:cast_booleans] || false

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

      @preprocess_quoter = proc do |x, named, indexed|
        @my_conn.quote((named[x] || indexed[x]).to_s)
      end

    end

    def disconnect
      @my_conn.close
      super
    end

    def transaction(&block)
      if in_transaction?
        raise RDBI::TransactionError.new( "Already in transaction (not supported by MySQL)" )
      end
      @my_conn.autocommit(false)
      super &block
      @my_conn.autocommit(true)
    end

    def rollback
      if ! in_transaction?
        raise RDBI::TransactionError.new( "Cannot rollback when not in a transaction" )
      end
      @my_conn.rollback
      super
    end

    def commit
      if ! in_transaction?
        raise RDBI::TransactionError.new( "Cannot commit when not in a transaction" )
      end
      @my_conn.commit
      super
    end

    def new_statement(query)
      Statement.new(query, self)
    end

    def table_schema(table_name)
    end

    def schema
    end

    def ping
      begin
        @my_conn.ping
        return 1
      rescue
        raise RDBI::DisconnectedError, "not connected"
      end
    end
  end

  #
  # Due to mysql statement handles and result sets being tightly coupled,
  # RDBI::Database#execute may require a full fetch of the result set for any
  # of this to work.
  #
  # If you *must* use execute, use the block form, which will wait to close any
  # statement handles. Performance will differ sharply.
  #
  class Cursor < RDBI::Cursor
    def initialize(handle)
      super(handle)
      @index = 0
    end

    def fetch(count=1)
      return [] if last_row?
      a = []
      count.times { a.push(next_row) }
      return a
    end

    def next_row
      val = if @array_handle
              @array_handle[@index]
            else
              @handle.fetch
            end

      @index += 1
      val
    end

    def result_count
      if @array_handle
        @array_handle.size
      else
        @handle.num_rows
      end
    end

    def affected_count
      if @array_handle
        0
      else
        @handle.affected_rows
      end
    end

    def first
      if @array_handle
        @array_handle.first
      else
        cnt = @handle.row_tell
        @handle.data_seek(0)
        res = @handle.fetch
        @handle.data_seek(cnt)
        res
      end
    end

    def last
      if @array_handle
        @array_handle.last
      else
        cnt = @handle.row_tell
        @handle.data_seek(@handle.num_rows)
        res = @handle.fetch
        @handle.data_seek(cnt)
        res
      end
    end

    def rest
      oindex, @index = [@index, @handle.num_rows] rescue [@index, @array_handle.size]
      fetch_range(oindex, @index)
    end

    def all
      fetch_range(0, (@handle.num_rows rescue @array_handle.size))
    end

    def [](index)
      @array_handle[index]
    end
    
    def last_row?
      if @array_handle
        @index == @array_handle.size
      else
        @handle.eof?
      end
    end

    def rewind
      @index = 0
      unless @array_handle
        @handle.data_seek(0)
      end
    end

    def empty?
      @array_handle.empty?
    end

    def finish
      @handle.free_result
    end
    
    def coerce_to_array
      unless @array_handle
        @array_handle = []
        begin
          @handle.num_rows.times { @array_handle.push(@handle.fetch) }
        rescue
        end
      end
    end

    protected

    def fetch_range(start, stop)
      if @array_handle
        @array_handle[start, stop]
      else
        ary = []

        @handle.data_seek(start)
        (stop - start).times do 
          @handle.fetch
        end
      end
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

      manipulate_type_maps
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

      columns = []
      metadata = res.result_metadata rescue nil

      if metadata
        columns = res.result_metadata.fetch_fields.collect do |col|
          RDBI::Column.new(
            col.name.to_sym,
            map_type(col),
            map_type(col).to_sym,
            col.length,
            col.decimals,
            !col.is_not_null?
          )
        end
      end

      schema = RDBI::Schema.new columns
      [ Cursor.new(res), schema, @output_type_map ]
    end

    def finish
      @my_query.close rescue nil
      super
    end

    protected

    def map_type(col)
      if col.is_num? && col.length == 1
        'boolean'
      else
        TYPE_MAP[col.type]
      end
    end

    def manipulate_type_maps
      datetime_check = proc { |x| x.kind_of?(::Mysql::Time) }
      zone = DateTime.now.zone
      # XXX yep. slow as snot.
      datetime_conv  = proc { |x| DateTime.parse(x.to_s + " #{zone}") }

      @output_type_map[:datetime] = RDBI::Type.filterlist(TypeLib::Filter.new(datetime_check, datetime_conv))

      @input_type_map[TrueClass] = TypeLib::Filter.new(
        RDBI::Type::Checks::IS_BOOLEAN,
        proc { |x| 1 }
      )
      
      @input_type_map[FalseClass] = TypeLib::Filter.new(
        RDBI::Type::Checks::IS_BOOLEAN,
        proc { |x| 0 }
      )

      if dbh.cast_booleans
        boolean_filter = TypeLib::Filter.new(
          proc { |x| x == 1 or x == 0 }, 
          proc { |x| x == 1 }
        )

        @output_type_map[:boolean] = boolean_filter
      end
    end
  end
end
