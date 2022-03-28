module Cluster
  module ConfigChecks
    class MisconfiguredPrebuiltOcSettings < StandardError; end

    class PrebuiltOcSettings < Base
      def self.sane?
        oc_prebuilt_artifacts = stack_custom_json.fetch(:oc_prebuilt_artifacts, {})

        if !oc_prebuilt_artifacts.empty? && is_truthy(oc_prebuilt_artifacts[:enable])
          if oc_prebuilt_artifacts[:bucket].nil? || oc_prebuilt_artifacts[:bucket].empty?
            raise MisconfiguredPrebuiltOcSettings.new("oc_prebuilt_artifacts misconfigured: missing a `bucket` value")
          end

          app_revision = app_config[:app_source][:revision]
          bucket = oc_prebuilt_artifacts[:bucket]

          begin
            bucket_exists = s3_client.head_bucket({
              bucket: bucket
            })
          rescue
            STDERR.puts "WARNING: oc_prebuilt_artifacts misconfigured: bucket '#{bucket}' not found!".colorize(:background => :red)
          end

          ['admin', 'presentation', 'worker'].each do |node_profile|
            key = "#{app_revision.gsub(/\//, "-")}/#{node_profile}.tgz"
            begin
              artifact_object = s3_client.head_object({
                bucket: bucket,
                key: key
              })
            rescue
            STDERR.puts "oc_prebuild_artifacts misconfigured: prebuild artifact '#{key}' not found in bucket '#{bucket}'!".colorize(:background => :red)
            end
          end
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::PrebuiltOcSettings)
