# db2_adapter.rb
# author: Maik Schmidt <contact@maik-schmidt.de>

require 'active_record/connection_adapters/abstract_adapter'

begin
  require 'db2/db2cli' unless self.class.const_defined?(:DB2CLI)
  require 'active_record/vendor/db2'

  module ActiveRecord
    class Base
      # Establishes a connection to the database that's used by
      # all Active Record objects
      def self.db2_connection(config) # :nodoc:
        symbolize_strings_in_hash(config)
        usr = config[:username]
        pwd = config[:password]

        if config.has_key?(:database)
          database = config[:database]
        else
          raise ArgumentError, "No database specified. Missing argument: database."
        end

        connection = DB2::Connection.new(DB2::Environment.new)
        connection.connect(database, usr, pwd)
        ConnectionAdapters::DB2Adapter.new(connection)
      end
    end

    module ConnectionAdapters
      class DB2Adapter < AbstractAdapter # :nodoc:
        def select_all(sql, name = nil)
          select(sql, name)
        end

        def select_one(sql, name = nil)
          select(sql, name).first
        end

        def insert(sql, name = nil, pk = nil, id_value = nil)
          execute(sql, name = nil)
          id_value || last_insert_id
        end

        def execute(sql, name = nil)
          rows_affected = 0

          log(sql, name, @connection) do |connection| 
            stmt = DB2::Statement.new(connection)
            stmt.exec_direct(sql)
            rows_affected = stmt.row_count
            stmt.free
          end

          rows_affected
        end

        alias_method :update, :execute
        alias_method :delete, :execute

        def begin_db_transaction
          @connection.set_auto_commit_off
        end

        def commit_db_transaction
          @connection.commit
          @connection.set_auto_commit_on
        end
        
        def rollback_db_transaction
          @connection.rollback
          @connection.set_auto_commit_on
        end

        def quote_column_name(name) name; end

        def quote_string(s)
          s.gsub(/'/, "''") # ' (for ruby-mode)
        end

        def add_limit!(sql, limit)
          sql << " FETCH FIRST #{limit} ROWS ONLY"
        end

        def columns(table_name, name = nil)
          stmt = DB2::Statement.new(@connection)
          result = []

          stmt.columns(table_name.upcase).each do |c| 
            c_name = c[3].downcase
            c_default = c[12] == 'NULL' ? nil : c[12]
            c_type = c[5].downcase
            c_type += "(#{c[6]})" if !c[6].nil? && c[6] != ''
            result << Column.new(c_name, c_default, c_type)
          end 

          stmt.free
          result
        end

        private
          def last_insert_id
            row = select_one(<<-GETID.strip)
            with temp(id) as (values (identity_val_local())) select * from temp
            GETID
            row['id'].to_i
          end

          def select(sql, name = nil)
            stmt = nil
            log(sql, name, @connection) do |connection|
              stmt = DB2::Statement.new(connection)
              stmt.exec_direct(sql + " with ur")
            end

            rows = []
            while row = stmt.fetch_as_hash
              rows << row
            end
            stmt.free
            rows
          end
      end
    end
  end
rescue LoadError
  # DB2 driver is unavailable.
end