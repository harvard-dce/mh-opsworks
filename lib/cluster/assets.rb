module Cluster
  class Assets < Base
    def self.list_objects_in(bucket: '')
      find_or_create_bucket(bucket)

      s3_client.list_objects(
        bucket: bucket
      ).contents.map(&:key)
    end

    def self.publish_support_asset_to(file_name: '', bucket: '')
      find_or_create_bucket(bucket)

      s3_client.put_object(
        acl: 'public-read',
        bucket: bucket,
        body: File.open(file_name),
        key: file_name
      )

      s3_client.wait_until(:object_exists, bucket: bucket, key: file_name)
    end

    # This is not efficient and should only be used for small objects
    def self.get_support_asset(file_name: '', bucket: '')
      find_or_create_bucket(bucket)

      response = nil
      begin
        response = s3_client.get_object(
          bucket: bucket,
          key: file_name
        )
      rescue => e
        return response
      end
      response.body.read
    end

    def self.delete_support_asset(file_name: '', bucket: '')
      find_or_create_bucket(bucket)
      s3_client.delete_object(
        bucket: bucket,
        key: file_name
      )
      s3_client.wait_until(:object_not_exists, bucket: bucket, key: file_name)
    end

    private

    def self.find_or_create_bucket(bucket_name)
      asset_bucket = s3_client.list_buckets.inject([]){ |memo, page| memo + page.buckets }.find do |bucket|
        bucket.name == bucket_name
      end

      return construct_bucket(bucket_name) if asset_bucket

      s3_client.create_bucket(
        acl: 'public-read',
        bucket: bucket_name
      )
      construct_bucket(bucket_name)
    end

    def self.construct_bucket(name)
      Aws::S3::Bucket.new(name, client: s3_client)
    end
  end
end
