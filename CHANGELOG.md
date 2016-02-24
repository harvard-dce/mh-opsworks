# CHANGELOG

## TO BE RELEASED

## 1.0.11 - 2/25/2016

* Open the squid proxy port for rfc 1918 addresses. Document how to set up
  zadara s3 object backups. This has essentially no effect for clusters that 
  don't use zadara object backups (not enabled by default). See README.zadara.md
  for more information.

## 1.0.10 - 2/16/2016

* Mount nfs earlier in the init process to ensure we correctly add disk space
  checks at the right time.
* Document multi-az RDS creation better. Create multi-az RDS by default for
  large clusters.

## 1.0.9 - 2/10/2016

* Allow unit tests to be run via the `deployment:redeploy_app_with_unit_tests`
  rake task.

## 1.0.8 - 2/4/2016

* Only set the bucket policy on the s3 distribution bucket on creation

## 1.0.7 - 2/2/2016

* Add a working bucket policy to the s3 distribution bucket

## 1.0.6 - 1/28/2016

* Auto-create the s3 distribution bucket with the correct CORS headers

## 1.0.5 - 1/21/2016

* Don't error out when deleting non-existing buckets

## 1.0.4 - 1/21/2016

* Remove the asset layer as it's replaced with the new s3 distribution.
* Autocreate an s3 bucket config value based on the cluster name.

## 1.0.3 - 1/19/2016

* Give additional rights to the default instance profile to allow the engage
  node to publish compiled assets to s3. This is part of the "seed from s3 to
  cloudfront" feature implemented in MATT-1727

## 1.0.2 - 1/6/2016

* Increase ebs workspace size for production-sized clusters

## 1.0.1 - 1/5/2016

* Allow private instances to access port 8081 through the NAT instance so that
  java nexus build servers can be used.

## 1.0.0 - 1/4/2016

* Initial release
