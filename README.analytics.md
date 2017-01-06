# Enabling the Analytics Node

The opsworks "Analytics" layer provides a full [ELK](https://www.elastic.co/products)
stack in a single instance. ELK = Elasticsearch + Logstash + Kibana. This is the stack of components used
for processing and indexing MH analytics data, particularly usertracking events.

To include an analytics node in your cluster simply say "Y" when prompted during the `cluster:new` process.

For an existing cluster, modify your cluster config to include the following layer config, then run `stack:instances:init`
to get the new node (which you can then start via the AWS console):

```
 {
   "name": "Analytics",
   "shortname": "analytics",
   "enable_auto_healing": true,
   "install_updates_on_boot": true,
   "type": "custom",
   "auto_assign_elastic_ips": true,
   "auto_assign_public_ips": true,
   "use_ebs_optimized_instances": true,
   "custom_recipes": {
     "setup": [
       "mh-opsworks-recipes::set-timezone",
       "mh-opsworks-recipes::fix-raid-mapping",
       "mh-opsworks-recipes::set-bash-as-default-shell",
       "mh-opsworks-recipes::install-utils",
       "mh-opsworks-recipes::install-crowdstrike",
       "mh-opsworks-recipes::install-mh-base-packages",
       "mh-opsworks-recipes::enable-postfix-smarthost",
       "mh-opsworks-recipes::install-custom-metrics",
       "mh-opsworks-recipes::create-alerts-from-opsworks-metrics",
       "mh-opsworks-recipes::enable-enhanced-networking",
       "mh-opsworks-recipes::install-cwlogs",
       "mh-opsworks-recipes::install-elasticsearch",
       "mh-opsworks-recipes::install-ua-harvester",
       "mh-opsworks-recipes::install-logstash-kibana",
       "mh-opsworks-recipes::clean-up-package-cache"
     ],
     "configure": [
       "mh-opsworks-recipes::configure-ua-harvester"
     ],
     "shutdown": [
       "mh-opsworks-recipes::remove-alarms"
     ]
   },
   "volume_configurations": [
     {
       "mount_point": "/vol/elasticsearch_data",
       "number_of_disks": 1,
       "size": "20",
       "volume_type": "gp2"
     }
   ],
   "instances": {
     "number_of_instances": 1,
     "instance_type": "t2.medium",
     "root_device_type": "ebs",
     "root_device_size": "8"
   }
 }
```

* also for existing clusters, update your "custom_json" block to provide a user/pass combo for http auth:

```
    {
        "elk": {
            "http_auth": {
                "user": "user",
                "pass": "pass"
            }
        }
    }
```
* re: *instance_type*, anything from `t2.medium` to `m4.large` is sufficient for development. If you're planning
to generate and query a large volume of user data during development, `m4.large` is recommended. 
For prod, or If you're doing any intensive bulk operations, `m4.xlarge` should be preferred.
* For a list of settings and defaults for the `"elk"` custom config, see the
  `get_elk_info` [recipe helper](https://github.com/harvard-dce/mh-opsworks-recipes/blob/master/libraries/default.rb) method.
* for older existing clusters you may need to manually update your cluster's instance
  profile to add SQS access. You can find it by viewing any of your stack's
  instances in the ec2 console, then find the "IAM Role" in the instance
  description, click that, then "Edit Policy" and add `"sqs:*"` to the allowed
  action list.
* execute `./bin/rake admin:cluster:init` and `./bin/rake stack:instances:start`
  to initialize and start the new layer/instance.
* See the **Kibana** section below for how to get started visualizing the data.

## What you get

* An "Analytics" layer with one instance running (`analytics1`):
  * Elasticsearch (bound to the private ip)
  * Logstash
  * Kibana
  * nginx acting as a reverse proxy to both Kibana and Elasticsearch. The proxy
    listens on both 80 & 443, but all traffic is forced to https and HTTP Basic
    auth is required.
  * a MH user action harvester script that fetches events from the engage node
    every 2 minutes.
* There will also be a "stack-name-user-actions" SQS queue created.
  The harvester script uses this queue to feed events to logstash.

### Kibana

The Kibana UI will be available at the public dns name of your logstash-kibana
instance. When first accessed you will be asked to create an index pattern. You
won't be able to do this yet because you likely don't have an events in your
index. Go watch a video! Give it at least 2 minutes for the events to be picked
up and indexed, then come back.

Type `useractions-*` into the pattern field, wait a second or two for the form
to populate the options, then select `@timestamp` as the
time-field name. Leave the checkboxes as is and click 'Create'. You'll see a
table of all the event fields in the index. You can now browse to the "Discover"
tab and search for events!

### Elasticsearch

Interaction with elasticsearch can be done directly via the public dns of the
logstash-kibana instance at the path `/es`. You can also explore indexes and
elasticsearch settings via the Kopf plugin at the path `/kopf`.

### Elasticsearch snapshots

By default your elasticsearch index will create daily, incremental snapshots
of your indexed data. Snapshots are stored in s3 at the path
`/elasticsearch-snapshots/<stack-name>`. To disable this set `es_enable_snapshots`
to `false` in your cluster config's `"elk"` stanza.

Manual create/restore of snapshots can be done via the Kopf interface. Click the
"more" tab and choose "snapshot".


