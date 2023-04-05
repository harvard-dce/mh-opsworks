module Cluster
  class S3DistributionBucket < Base
    def self.find_or_create(bucket_name)
      bucket = S3Bucket.find_existing(name: bucket_name)
      return bucket if bucket

      S3Bucket.create(name: bucket_name)
      s3_client.put_public_access_block({
        bucket: bucket_name,
        public_access_block_configuration: {
          block_public_policy: false
        }
      })
      s3_client.put_bucket_policy(
        bucket: bucket_name,
        policy: default_bucket_policy_for(bucket_name)
      )
      s3_client.put_bucket_cors(
        bucket: bucket_name,
        cors_configuration: {
          cors_rules: [
            allowed_headers: ['*'],
            allowed_methods: ['GET','HEAD'],
            allowed_origins: ['*'],
            max_age_seconds: 3600
          ]
        }
      )
    end

    def self.delete(bucket_name)
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

    def self.default_bucket_policy_for(bucket_name)
     %Q|{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::#{bucket_name}/*"
    }
  ]
}|
    end
  end
end
