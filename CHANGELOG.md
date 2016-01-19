# CHANGELOG

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
