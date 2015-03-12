module Cluster
  class App < Base
    include Waiters

    def self.delete
      app = find_existing_app
      if app
        opsworks_client.delete_app(app_id: app.app_id)
      end
    end

    def self.find_or_create
      stack = Stack.find_or_create

      app = find_existing_app
      return app if app

      app = opsworks_client.create_app(
        stack_id: stack.stack_id,
        name: app_config[:name],
        shortname: app_config[:shortname],
        data_sources: [
          { type: 'AutoSelectOpsworksMysqlInstance' }
        ],
        type: app_config[:type],
        app_source: app_config[:app_source]
      )
      wait_until_app_available(app.app_id)
      find_existing_app
    end

    def self.find_existing_app
      vpc = Cluster::VPC.find_existing
      stack = Cluster::Stack.find_existing_in(vpc)
      stack && opsworks_client.describe_apps(stack_id: stack.stack_id).apps.find do |app|
        app.name == app_config[:name]
      end
    end
  end
end
