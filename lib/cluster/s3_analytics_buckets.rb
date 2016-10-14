module Cluster
  class S3AnalyticsBuckets < S3DistributionBucket
    def self.delete
      [analytics_es_snapshots_bucket_name, analytics_ua_harvester_bucket_name].each do |bucket_name|
        begin
          delete_objects_from(bucket_name)
          delete_versions_from(bucket_name)
          delete_delete_markers_from(bucket_name)
          delete_bucket(bucket_name)
        rescue Aws::S3::Errors::NoSuchBucket
          puts "#{bucket_name} did not exist. Continuing. . ."
        end
      end
    end
  end
end
