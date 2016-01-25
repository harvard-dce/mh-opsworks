module Cluster
  class S3Bucket < Base
    def self.find_or_create(name: '', permissions: 'private')
      asset_bucket = s3_client.list_buckets.inject([]){ |memo, page| memo + page.buckets }.find do |bucket|
        bucket.name == name
      end

      return construct_bucket(name) if asset_bucket

      s3_client.create_bucket(
        acl: (permissions == 'private') ? 'private' : 'public-read',
        bucket: name
      )
      s3_client.put_bucket_versioning(
        bucket: name,
        versioning_configuration: {
          mfa_delete: 'Disabled',
          status: 'Enabled'
        }
      )
      construct_bucket(name)
    end

    def self.construct_bucket(name)
      Aws::S3::Bucket.new(name, client: s3_client)
    end
  end
end
