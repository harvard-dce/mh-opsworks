module Cluster
  class App < Base
    include Waiters

    def self.delete
      app = find_existing
      if app
        opsworks_client.delete_app(app_id: app.app_id)
      end
    end

    def self.find_or_create
      stack = Stack.find_or_create

      app = find_existing
      return app if app

      app_source = app_config[:app_source]
      if deployment_private_ssh_key
        app_source[:ssh_key] = deployment_private_ssh_key
      end

      app = opsworks_client.create_app(
        stack_id: stack.stack_id,
        name: app_config[:name],
        shortname: app_config[:shortname],
        data_sources: [
          { type: 'AutoSelectOpsworksMysqlInstance' }
        ],
        type: app_config[:type],
        app_source: app_source
      )
      wait_until_app_available(app.app_id)
      find_existing
    end

    def self.find_existing
      stack = Cluster::Stack.find_existing
      stack && opsworks_client.describe_apps(stack_id: stack.stack_id).inject([]){ |memo, page| memo + page.apps }.find do |app|
        app.name == app_config[:name]
      end
    end
  end
end
