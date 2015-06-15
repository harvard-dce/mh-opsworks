module EnvironmentHelpers
  def stub_config_to_include(config_variables)
    allow_any_instance_of(Cluster::Config).to receive(:parsed).and_return(
      base_config.merge!(config_variables)
    )
  end

  def stub_secrets_to_include(config_variables)
    allow_any_instance_of(Cluster::Config).to receive(:parsed_secrets).and_return(
      base_secrets.merge!(config_variables)
    )
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  def with_no_mhopsworks_rc
    rc_file = '.mhopsworks.rc'
    if File.exists?(rc_file)
      original_content = File.read(rc_file)
      File.unlink(rc_file)
    end

    begin
      yield
    ensure
      if original_content
        File.open(rc_file, 'w') do |f|
          f.write original_content
        end
      end
    end
  end

  def with_retained_config_file(config_file)
    cached_contents = File.read(config_file)
    begin
      yield
    ensure
      File.open(config_file, 'w') do |fh|
        fh.write cached_contents
      end
    end
  end

  def with_valid_json_config
    with_modified_env(
      CLUSTER_CONFIG_FILE: 'templates/cluster_config_default.json.erb'
    ) do
      yield
    end
  end

  def base_config
    @base_config ||= JSON.parse(
      File.read('templates/cluster_config_default.json.erb'),
      symbolize_names: true
    )
  end

  def base_secrets
    @base_secrets ||= JSON.parse(
      File.read('templates/secrets_example.json'),
      symbolize_names: true
    )
  end
end
