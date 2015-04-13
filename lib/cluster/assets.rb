module Cluster
  class Assets < Base
    def self.publish_support_asset(file_name)
      find_or_create_shared_asset_bucket

      s3_client.put_object(
        acl: 'public-read',
        bucket: shared_asset_bucket_name,
        body: File.open(file_name),
        key: file_name
      )

      s3_client.wait_until(:object_exists, bucket: shared_asset_bucket_name, key: file_name)
    end

    private

    def self.find_or_create_shared_asset_bucket
      asset_bucket = s3_client.list_buckets.buckets.find do |bucket|
        bucket.name == shared_asset_bucket_name
      end

      return construct_bucket(shared_asset_bucket_name) if asset_bucket

      s3_client.create_bucket(
        acl: 'public-read',
        bucket: shared_asset_bucket_name
      )
      construct_bucket(shared_asset_bucket_name)
    end

    def self.construct_bucket(name)
      Aws::S3::Bucket.new(name, client: s3_client)
    end

  end
end
