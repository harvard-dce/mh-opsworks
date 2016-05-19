module Cluster
  class S3ArchiveBucket < S3DistributionBucket
    def self.find_or_create(bucket_name)
      bucket = S3Bucket.find_existing(name: bucket_name)
      return bucket if bucket

      S3Bucket.create(name: bucket_name)

      s3_client.put_bucket_lifecycle_configuration({
        bucket: bucket_name,
        lifecycle_configuration: {
          rules: [
            {
              id: "Rotate to Infrequent Access after 30 days",
              prefix: "",
              status: "Enabled",
              transitions: [
                {
                  days: 30,
                  storage_class: "STANDARD_IA",
                },
              ],
              noncurrent_version_expiration: {
                noncurrent_days: 30,
              },
            },
          ]
        }
      })
    end
  end
end
