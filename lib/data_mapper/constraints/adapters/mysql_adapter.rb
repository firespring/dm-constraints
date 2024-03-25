require 'data_mapper/constraints/adapters/do_adapter'

module DataMapper
  module Constraints
    module Adapters
      module MysqlAdapter
        include SQL, DataObjectsAdapter

        module SQL
          ##
          # MySQL specific query to drop a foreign key
          #
          # @see DataMapper::Constraints::Adapters::DataObjectsAdapter#destroy_constraints_statement
          #
          # @api private
          private def destroy_constraints_statement(storage_name, constraint_name)
            DataMapper::Ext::String.compress_lines(<<-SQL)
              ALTER TABLE #{quote_name(storage_name)}
              DROP FOREIGN KEY #{quote_name(constraint_name)}
            SQL
          end
        end
      end
    end
  end
end
