module Cluster
  class S3DistributionBucket < Base
    def self.find_or_create
      S3Bucket.find_or_create(
        name: distribution_bucket_name, permissions: 'public'
      )
      s3_client.put_bucket_cors(
        bucket: distribution_bucket_name,
        cors_configuration: {
          cors_rules: [
            allowed_headers: ['Authorization'],
            allowed_methods: ['GET'],
            allowed_origins: ['*'],
            max_age_seconds: 3600
          ]
        }
      )
    end

    def self.delete
      bucket_name = distribution_bucket_name
      begin
        delete_objects_from(bucket_name)
        delete_versions_from(bucket_name)
        delete_delete_markers_from(bucket_name)
        delete_bucket(bucket_name)
      rescue Aws::S3::Errors::NoSuchBucket
        puts "#{bucket_name} did not exist. Continuing. . ."
      end
    end

    private

    def self.delete_bucket(bucket_name)
      s3_client.delete_bucket(bucket: bucket_name)
    end

    def self.delete_delete_markers_from(bucket_name)
      objects = s3_client.list_object_versions(bucket: bucket_name).inject([]){ |memo, page| memo + page.delete_markers }
      delete_objects(objects, bucket_name)
    end

    def self.delete_versions_from(bucket_name)
      objects = s3_client.list_object_versions(bucket: bucket_name).inject([]){ |memo, page| memo + page.versions }
      delete_objects(objects, bucket_name)
    end

    def self.delete_objects_from(bucket_name)
      objects = s3_client.list_objects(bucket: bucket_name).inject([]){ |memo, page| memo + page.contents }
      delete_objects(objects, bucket_name)
    end

    def self.delete_objects(objects, bucket_name)
      objects.each_slice(500) do |object_slice|
        s3_client.delete_objects({
          bucket: bucket_name,
          delete: {
            objects: object_slice.map{ |object| object_keys_to_delete(object)  }
          }
        })
      end
    end

    def self.object_keys_to_delete(object)
      if object.respond_to?(:version_id)
        { key: object.key, version_id: object.version_id }
      else
        { key: object.key }
      end
    end

    def self.distribution_bucket_name
      stack_custom_json[:s3_distribution_bucket_name]
    end
  end
end
