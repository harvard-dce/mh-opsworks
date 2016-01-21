# CHANGELOG

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
