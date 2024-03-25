# TODO: figure out some other (less tightly coupled) way to ensure that
# dm-migrations' method implementations are loaded before this file
require 'dm-migrations/auto_migration'

module DataMapper
  module Constraints
    module Migrations
      module Model
        # @api private
        def auto_migrate_constraints_up(repository_name = self.repository_name)
          # TODO: this check should not be here
          return if respond_to?(:is_remixable?) && is_remixable?

          relationships(repository_name).each do |relationship|
            relationship.auto_migrate_constraints_up(repository_name)
          end
        end

        # @api private
        def auto_migrate_constraints_down(repository_name = self.repository_name)
          return unless storage_exists?(repository_name)
          # TODO: this check should not be here
          return if respond_to?(:is_remixable?) && is_remixable?

          relationships(repository_name).each do |relationship|
            relationship.auto_migrate_constraints_down(repository_name)
          end
        end
      end
    end
  end

  Model.append_extensions Constraints::Migrations::Model
end
