module Cluster
  class S3Bucket < Base

    include ConfigurationHelpers

    def self.find_existing(name: '')
      asset_bucket = s3_client.list_buckets.inject([]){ |memo, page| memo + page.buckets }.find do |bucket|
        bucket.name == name
      end

      return construct_bucket(name) if asset_bucket
    end

    def self.create(name: '', permissions: 'private')
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

      s3_client.put_bucket_tagging(
        bucket: name,
        tagging: {
          tag_set: [
            {
              key: 'opsworks:stack',
              value: stack_config[:name]
            }
          ].concat(stack_custom_tags)
        }
      )

      construct_bucket(name)
    end

    def self.find_or_create(name: '', permissions: 'private')
      bucket = find_existing(name: name)
      return bucket if bucket

      create(name: name, permissions: 'private')
    end

    def self.construct_bucket(name)
      Aws::S3::Bucket.new(name, client: s3_client)
    end
  end
end
