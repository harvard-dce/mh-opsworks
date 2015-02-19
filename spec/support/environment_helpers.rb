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
      CLUSTER_CONFIG_FILE: 'templates/cluster_config_example.json'
    ) do
      yield
    end
  end

  def base_config
    @base_config ||= JSON.parse(
      File.read('templates/cluster_config_example.json'),
      symbolize_names: true
    )
  end
end
