module Cluster
  class Assets < Base
    def self.list_objects_in(bucket: '')
      S3Bucket.find_or_create(name: bucket)

      s3_client.list_objects(
        bucket: bucket
      ).contents.map(&:key)
    end

    def self.publish_support_asset_to(file_name: '', bucket: '', permissions: 'private')
      S3Bucket.find_or_create(name: bucket, permissions: permissions)

      s3_client.put_object(
        acl: (permissions == 'private') ? 'bucket-owner-full-control' : 'public-read',
        bucket: bucket,
        body: File.open(file_name),
        key: file_name
      )

      s3_client.wait_until(:object_exists, bucket: bucket, key: file_name)
    end

    # This is not efficient and should only be used for small objects
    def self.get_support_asset(file_name: '', bucket: '')
      S3Bucket.find_or_create(name: bucket)

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
      S3Bucket.find_or_create(name: bucket)
      s3_client.delete_object(
        bucket: bucket,
        key: file_name
      )
      s3_client.wait_until(:object_not_exists, bucket: bucket, key: file_name)
    end
  end
end
