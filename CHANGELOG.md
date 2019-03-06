# CHANGELOG

## TO BE RELEASED

## 2.3.0 - 03/06/2019

* MI-158: hibernate/restore vpsa during `stack:intances:start|stop`

## 2.2.0 - 02/13/2019

* MI-150: `cluster:new` asks for cookbook revision, no longer asks for cookbook source type
* MI-149: adding tasks to hibernate/restore the dev zadara vpsa

## 2.1.0 - 01/15/2019

* MI-144: vpn/ca ips are now in `base-secrets.json` so look for them in the custom json instead of local secrets

## 2.0.0 - 01/14/2019

These changes all relate or were implemented during the Opencast 1.x -> 5.x migration work

* t/MI-122: update all gems to latest versions
* b/MI-124: redo db subnet group; remove db subnet
* b/MI-119: set storage type to general pupose ssd
* t/MI-118: force cluster names to lowercase
* open iperf3 port from capture agents in common security group
* set default cluster cookbook revision to "oc-opsworks-5.x-recipes" (for now)
* MI-100: add vpc filter to security group finder api call (cherry-picked from main line)
* MI-98: remove EFS storage support
* MI-95: use multiple private subnets/AZs so worker spin-up isn't vulnerable to AZ capacity issues
* Incorporate utility layer/node creation into `cluster:new`
* enable RDS performance insights
* MI-125: rename maven cache file
* MI-127: remove crowdstrike install from runlists
* MI-130: `PermissionsSyncer` now compares configured user `ssh_key` value with existing and updates if they differ
* sleep a little longer waiting for the `ssh_users` deployment to inititate
* include `create-opencast-directories` recipe in local vagrant setup runlists to ensure
  directories are created on first `up` / deployment
* MI-97: RDS Aurora clusters
* remove enhanced networking setup recipe from runlists
* add mh-opsworks version compatability check
* MI-134: find and use latest amis in cluster config
* fix for empty sns email
* add additional instance info to `stack:instances:list` output
* add option to `stack:instances:stop` to prevent stopping rds cluster
* don't try to unsub pending sns subscriptions
* Allow db.t2.small/medium RDS types; enable performance insights only for r4/3 types
* Add newrelic install recipe to OC node runlists.
* replacing `install-queued-jobs-metric` recipe with expanded `install-opencast-job-metrics`
  Note: a stub of the old recipe remains in the cookbook for backwards compatibility
* zadara cluster config template was missing chef log level setting

## 1.17.2 - 10/25/2018

* set rds `storage_type` to 'gp2' as default is not what we want
* add vpc filter to security group finder API call because performance

## 1.17.1 - 06/05/2018

* MI-89: Don't bother specifying ebs optimization in layer settings. Instance types where we'd want
  it will have it enabled automatically anyway.

## 1.17.0 - 05/11/2018

* insert missing `install-cwlogs` recipe in zadara cluster config template
* add `num_workers=n` option to `stack:instances:start` to allow only starting *n* workers.

## 1.16.1 - 12/13/2017

* swap '/' for '-' in s3 cookbook source package names

## 1.16.0 - 12/07/2017

* 'activesupport' gem updated to address security vulnerability
* fail more nicely when VPN/capture agent IPs aren't configured in secrets
* add NAT Gateway's IP to common security group ingress rules
* include db parameter group value in rds params
* `custom_cookbooks_source` can now be s3 (default) or git

## 1.15.0 - 08/24/2017

* new rake tasks for pausing & resuming horizontal scaling: `moscaler:pause` & `moscaler:resume`.

## 1.14.1 - 08/15/2017

* fix formatting of service role policy doc entry

## 1.14.0 - 08/16/2017

* Security changes for MATT-2377

## 1.13.0 - 08/10/2017

* update rds mysql version
* Vagrantfile config fix for local-up ssh timeout on Mac OS X (MATT-2293)
* fix js typo in cluster config templates
* execute cluster:edit's stack, app & layer updates in parallel

## 1.12.0 - 01/10/2017

* Crowdstrike install recipe added to cluster config templates
* Delete any RDS hibernation snapshots on cluster delete

## 1.11.0 - 11/28/2016

* Make it easier to add an analytics node via `cluster:new`
* Allow configtest override for advanced, edge case clusters via `skip_configtest`.
* RDS hibernation via snapshot + delete & re-creation

## 1.10.0 - 10/19/2016

* don't use the `--binstubs` flag in `bin/setup`
* Include new `install-cwlogs` recipe in cluster config templates. 
  Add IAM policy permissions for managing cloudwatch log groups. 
  On rollout the "oc-opsworks-cluster-managers" IAM group will need to be manually updated to 
  include the new "logs:*" and "sqs:*" permissions. Existing clusters will need to run 
  `./bin/rake stack:users:init` to sync their respective cluster manager user.
  Add deletion of additional cluster artifacts, including cloudwatch log groups
  and sqs queues & buckets related to the analytics node.

## 1.9.0 - 9/16/2016

* custom tagging as rake task

## 1.8.1 - 9/08/2016

* add the `install-job-queued-metric` recipe to the Ganglia layer's setup list
* downward adjustments to default instance types and volume sizes

## 1.8.0 - 8/11/2016

* tag provisioned s3 buckets with the opsworks stack name
* Fix a couple of issues that resulted in modifications to files as a
  side-effect of running `bin/setup`.
* prompt user to consider using a local vagrant cluster
* removed unnecessary `/var/matterhorn-workspace` volume definition from
  workers layer config in all cluster config templates.
* add opsworks:DescribeLayers action to instance profile policy

## 1.7.1 - 7/20/2016

* Configure waiters to do "exponential backoff" when waiting for resources
  to become available/deleted.
* increase `retry_limit` on AWS client objects to alleviate failures due to 
  API throttling errors
* Rename of moscaler install recipe in cluster config templates &
  updates to horizontal scaling docs

## 1.7.0 - 7/15/2016

* Add `custom_json` item for controlling chef log level.
* Added policy to S3 file archive bucket (2-week project) so that nothing can be deleted in production.

## 1.6.2 - 6/24/2016

* Provide convenience defaults when executing `cluster:new`.
* bump analytics node instance type and ebs size

## 1.6.1 - 6/08/2016

* Allow `install_updates_on_boot` to be configured when a layer is created or
  updated. As far as I can tell, this doesn't get retroactively applied to
  instances in a layer that've already been created. This is a setting in each
  layer's config.

## 1.6.0 - 5/31/2016

* Increase the default root ebs volume size to 16G and allow for it to be
  customized in the cluster template. This only applies to new instances - you
  must delete and recreate an instance for it to get an increased root volume
  size with this change.
* Create the `s3_file_archive_bucket_name` attribute during cluster creation.
  Also create the bucket during `admin:cluster:init` and delete it during
  `admin:cluster:delete`. This is necessary for the auto archiving features soon
  to land in matterhorn-dce-fork.  To add the file archive bucket to an existing
  cluster: 1) Edit the cluster config,  2) create a unique and appropriate
  `s3_file_archive_bucket_name` right below the `s3_distribution_bucket_name`
  (probably something like <cluster_name>-file-archive), 3) Run
  `admin:cluster:init` to ensure the bucket is created, and then 4) deploy the
  version of matterhorn that contains the archiving code. It is OK if you create
  the bucket before the deploy, it'll just sit there waiting.

## 1.5.0 - 5/19/2016

* Delete stack-level alarms when removing a cluster. Fix issue where alarms
  were not being removed using the correct instance id.
* Add event subscriptions to RDS clusters to watch for failure and failover
  events, sending notifications to the default SNS topic. To roll out, Be sure
  to update the "oc-opsworks-cluster-managers" IAM group to include the new
  rights (it should match `templates/example_group_inline_policy.json`). New
  clusters will automatically get these subscriptions. To update an existing
  cluster, switch into it and run `./bin/rake rds:create_event_subscriptions`
* Fix `stack:commands:update_packages`, which will correctly apply only bug-
  and security- fixes.
* Implement "vpc:update" rake task to allow for vpc cloudformation
  infrastructure to be applied when the template changes.  cloudformation will
  incrementally apply changes to the template. This allows for new routes,
  security groups and other attributes to changed easily and precisely.

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
