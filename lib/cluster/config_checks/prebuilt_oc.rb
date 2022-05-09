module Cluster
  module ConfigChecks
    class MisconfiguredPrebuiltOcSettings < StandardError; end

    class PrebuiltOcSettings < Base
      def self.sane?
        prebuilt_artifacts = stack_custom_json.fetch(:oc_prebuilt_artifacts, {})
        bucket = prebuilt_artifacts[:bucket]
        bucket_configured = !bucket.nil? && !bucket.empty?
        enable_opencast = is_truthy(prebuilt_artifacts[:enable])

        if bucket_configured
          begin
            bucket_exists = s3_client.head_bucket({
              bucket: bucket
            })
          rescue
            STDERR.puts "WARNING: prebuilt_artifacts misconfigured: bucket '#{bucket}' not found!".colorize(:background => :red)
          end

          # verify the prebuilt opencast artifats are there
          if enable_opencast
            app_revision = app_config[:app_source][:revision]

            puts "Checking for prebuilt artifacts"
            ['admin', 'presentation', 'worker'].each do |node_profile|
              key = "opencast/#{app_revision.gsub(/\//, "-")}/#{node_profile}.tgz"
              begin
                artifact_object = s3_client.head_object({
                  bucket: bucket,
                  key: key
                })
                puts " \u2713 ".encode("utf-8").colorize(:background => :green) + " #{key} found in #{bucket}"
              rescue
                STDERR.puts "WARNING: prebuild opencast artifact '#{key}' not found in bucket '#{bucket}'!".colorize(:background => :red)
              end
            end
          end

          # verify the prebuilt cookbook is there
          if bucket_configured
            cookbook_source = stack_chef_config.fetch(:custom_cookbooks_source, {})
            if cookbook_source[:type] == "s3"
              cookbook_revision = cookbook_source[:revision].gsub(/\//, "-")
              cookbook_object_key = %Q|cookbook/#{cookbook_revision}/mh-opsworks-recipes-#{cookbook_revision}.tar.gz|
              begin
                cookbook_object = s3_client.head_object({
                  bucket: bucket,
                  key: cookbook_object_key
                })
                puts " \u2713 ".encode("utf-8").colorize(:background => :green) + " #{cookbook_object_key} found in #{bucket}"
              rescue
                STDERR.puts "WARNING: prebuild cookbook '#{cookbook_object_key}' not found in bucket '#{bucket}'!".colorize(:background => :red)
              end
            end
          end
        end
      end
    end
  end
end

Cluster::Config.append_to_prebuilt_artifacts_check_registry(Cluster::ConfigChecks::PrebuiltOcSettings)
