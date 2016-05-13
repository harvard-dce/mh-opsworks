# CHANGELOG

## TO BE RELEASED

* Delete stack-level alarms when removing a cluster. Fix issue where alarms
  were not being removed using the correct instance id.
* Add event subscriptions to RDS clusters to watch for failure and failover
  events, sending notifications to the default SNS topic. To roll out, Be sure
  to update the "mh-opsworks-cluster-managers" IAM group to include the new
  rights (it should match `templates/example_group_inline_policy.json`). New
  clusters will automatically get these subscriptions. To update an existing
  cluster, switch into it and run `./bin/rake rds:create_event_subscriptions`
* Fix `stack:commands:update_packages`, which will correctly apply only bug-
  and security- fixes.

## 1.4.0 - 5/10/2016

* improved tooling to spin up local vagrant-backed all-in-one nodes. See
  `README.local-opsworks.md` for details.

## 1.3.1 - 5/5/2016

* Fix a bug in the local opsworks support where the package repos weren't up to
  date on instance boot before the first package install.

## 1.3.0 - 4/20/2016

* Local opsworks cluster support. See `README.local-opsworks.md` for details.

## 1.2.1 - 4/xx/2016

* Add SQS access to the instance profile policy document.
* Document ELK component layer configuration and provided services.

## 1.2.0 - 3/23/2016

* Allow for cluster state to be turned into a "seed file" and applied to
  another cluster.  See `README.cluster_seed_files.txt` for more information on
  how this feature works.
* Very minor - don't write to `templates/minimal_cluster_config.json`.

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
