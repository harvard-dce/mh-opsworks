module Cluster
  class App < Base
    include Waiters

    def self.delete
      app = find_existing
      if app
        opsworks_client.delete_app(app_id: app.app_id)
      end
    end

    def self.update
      app = find_existing
      if app
        parameters = app_parameters

        # the update_app method doesn't like the ARNs for our rds cluster instances, possibly a bug
        # for now we'll just skip sending the :data_source information since it only otherwise contains the
        # db name, which is unlikely to change. In addition, the actual db instance registered with the
        # app doesn't matter because we override the "host" value of the db during deployment
        # see: Cluster::Stack.stack_parameters
        [:stack_id, :shortname, :data_sources].each do |key|
          parameters.delete(key)
        end
        opsworks_client.update_app(
          parameters.merge(app_id: app.app_id)
        )
      end
    end

    def self.find_or_create
      app = find_existing
      return app if app

      app = opsworks_client.create_app(app_parameters)
      wait_until_app_exists(app.app_id)
      find_existing
    end

    def self.find_existing
      stack = Cluster::Stack.find_existing
      stack && opsworks_client.describe_apps(stack_id: stack.stack_id).inject([]){ |memo, page| memo + page.apps }.find do |app|
        app.name == app_config[:name]
      end
    end

    private

    def self.app_parameters
      stack = Stack.find_existing
      app_source = app_config[:app_source]
      rds_arn = Cluster::RDS.writer_instance_arn

      if deployment_private_ssh_key
        app_source[:ssh_key] = deployment_private_ssh_key
      end

      data_source = {
        type: 'RdsDbInstance',
        database_name: rds_config[:db_name],
        arn: rds_arn
      }

      {
        stack_id: stack.stack_id,
        name: app_config[:name],
        shortname: app_config[:shortname],
        data_sources: [data_source],
        type: app_config[:type],
        app_source: app_source
      }
    end
  end
end
