module EnvironmentHelpers
  def stub_config_to_include(config_variables)
    allow_any_instance_of(Cluster::Config).to receive(:json).and_return(
      base_config.merge!(config_variables)
    )
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  def with_valid_json_config
    with_modified_env(
      CLUSTER_CONFIG_FILE: 'spec/support/files/valid_configuration.json'
    ) do
      yield
    end
  end

  def base_config
    @base_config ||= {
      region: "us-east-1",
      credentials: {
        access_key_id: "fake_access_key_id",
        secret_access_key: "fake_secret_access_key"
      },
      vpc: {
        name: "FILL_ME_IN",
        cidr_block: "FILL_ME_IN"
      }
    }
  end
end
