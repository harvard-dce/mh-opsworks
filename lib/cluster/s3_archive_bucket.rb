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
              id: "Move to IA after 30 days, Glacier IR after +60",
              prefix: "",
              status: "Enabled",
              transitions: [
                {
                  days: 30,
                  storage_class: "STANDARD_IA",
                },
                {
                  days: 60,
                  storage_class: "GLACIER_IR",
                },
              ],
              noncurrent_version_expiration: {
                noncurrent_days: 30,
              },
              abort_incomplete_multipart_upload: {
                days_after_initiation: 1,
              },
            },
          ]
        }
      })

      # Do not allow deletions in production
      if !dev_or_testing_cluster?
        policy = {
            "Version" => "2008-10-17",
            "Id" => "ProtectionAgainstDeleteInProd",
            "Statement" => [
              {
                "Sid" => "1",
                "Effect" => "Deny",
                "Principal" => {"AWS" => "*"},
                "Action" => "s3:DeleteBucket",
                "Resource" => "arn:aws:s3:::#{bucket_name}"
              },
              {
                "Sid" => "2",
                "Effect" => "Deny",
                "Principal" => {"AWS" => "*"},
                "Action" => "s3:DeleteObject",
                "Resource" => "arn:aws:s3:::#{bucket_name}/*"
              }
            ]
        }
        require 'json'
        s3_client.put_bucket_policy({
          bucket: bucket_name,
          policy: policy.to_json 
        })
      end
    end
  end
end
