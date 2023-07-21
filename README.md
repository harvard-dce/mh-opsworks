# oc-opsworks [![Build Status](https://secure.travis-ci.org/harvard-dce/oc-opsworks.png?branch=master)](https://travis-ci.org/harvard-dce/oc-opsworks) [![Code Climate](https://codeclimate.com/github/harvard-dce/mh-opsworks/badges/gpa.svg)](https://codeclimate.com/github/harvard-dce/mh-opsworks)

An amazon [OpsWorks](https://aws.amazon.com/opsworks/) implementation of a
opencast cluster.

## Requirements

* Ruby 2.3+
* Git
* Appropriately configured aws rights linked to an access key
* A POSIX operating system

## What you get

* Complete isolation for opencast production, staging, and development environments with environment parity,
* OpsWorks layers and EC2 instances for your admin, engage, worker, and support nodes,
* Automated monitoring and alarms via Ganglia and aws cloudwatch,
* A set of custom chef recipes that can be used to compose other layer and instance types,
* A flexible configuration system allowing you to scale instance sizes appropriately for your cluster's role,
* Security out of the box - instances can only be accessed via ssh keys and most instances are isolated to a private network,
* Automated opencast git deployments via OpsWorks built-ins,
* The ability to create and destroy opencast clusters completely, including all attached resources,
* A set of high-level rake tasks designed to make managing your OpsWorks opencast cluster easier,
* A way to switch between existing clusters to make collaboration easier,
* A MySQL RDS Aurora cluster that's monitored with cloudwatch alarms, and
* Rake level docs for each task, accessed via "rake -D <task name>".

## Getting started

### Step 0 - Create account-wide groups and policies (aws account admin only)

Ask an account administrator to create an IAM group with the
"AWSOpsWorksFullAccess" managed policy and an inline policy as defined in
`./templates/example_group_inline_policy.json`.  Name it something like
`oc-opsworks-cluster-managers`. You only need to do this once per AWS account.

This group allows a user to create / delete clusters including the VPC,
cloudformation templates, SNS topics, cloudwatch metrics, alarms and
numerous other AWS resources.

### Step 1 - Create your account and credentials

Create an IAM user and ensure it's in the group you created in "Step 0". Create
an aws access key pair for this user and have it handy. You'll use this account
to manage clusters.

It's easier if your IAM cluster manager account username doesn't match the one
you'd like to use to SSH into your clusters. If your name is "Jane Smith", your
IAM cluster manager user might be "janesmith-cluster-manager" while your stack
SSH username would be "janesmith".

### Step 2 - Install oc-opsworks

You must have ruby 2.3 or later installed, ideally through something like
[rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/), though
if your system ruby is >= 2.3 you should be fine.

You must also have [bundler]() version 2+ installed or `./bin/setup` will complain.
You can run `gem install bundler` to install it or `gem update bundler` if you have an older version.

`./bin/setup` installs prerequisites and sets up a template `secrets.json`.

You should fill in the template `secrets.json` with the cluster manager user
credentials you created previously and a `cluster_config_bucket_name` you'll
use for your team to store your cluster configuration files.

    git clone https://github.com/harvard-dce/mh-opsworks oc-opsworks/
    cd oc-opsworks
    ./bin/setup # checks for dependencies and sets up template env files

The base scripts (`rake`, mostly) live in `$REPO_ROOT/bin` and all paths below
assume you're in repo root.

### Step 3 - Choose (or create) your configuration files.

Assuming you've set up your `secrets.json` correctly, you can start working with
clusters.

If you'd like to work in an existing cluster, run:

    ./bin/rake cluster:switch

If you'd like to create a new cluster entirely, run:

    ./bin/rake cluster:new

and follow the prompts.

Be sure to set up the "users" stanza with your desired SSH username, rights,
and public key.  Following the example set in Step 1, it'd be "janesmith".

It's easiest if your SSH user matches your default local unix username as
the `stack:instances:ssh_to` rake task will work out of the box.

A default git url can be provided by setting `OPENCAST_GIT_URL` in your shell.

### Step 4 - Sanity check your cluster configuration

We've implemented a set of sanity checks to ensure your cluster configuration
looks right. They are by no means comprehensive, but serve as a basic
pre-flight check. The checks are run automatically before most `rake` tasks.

    # sanity check your cluster configuration
    ./bin/rake cluster:configtest

You'll see a relatively descriptive error message if there's something wrong
with your cluster configuration. If there's nothing wrong, you'll see no
output.

### Step 5 - Spin up your cluster

    ./bin/rake admin:cluster:init

This will create the VPC, RDS cluster, opsworks stack, layers, and instances according to
the parameters and sizes you set in your cluster config. Basic feedback is
given while the cluster is being created, you can see more information in the
AWS opsworks console.

At this point your opsworks instances have been initialized but no ec2 instances
have been created. The RDS cluster **has** been created and will be running (and
incurring AWS costs). If you do not intend to go on to the next step at this time
you should consider running `./bin/rake rds:stop` which will turn off the RDS cluster.
When you are eventually ready to move on to step 6, the `stack:instances:start`
command will restore the RDS cluster from it's stopped state.

**Note**: running `rds:stop` immediately after `admin:cluster:init`
can sometimes return an error that the RDS instance is in a non-modifiable state.
This is fine; it's just the instance doing it's usual automated backup when it first
comes online. Wait 5-10m or so and try again.

**Note**: the rake tasks attempts to run some of the initialization steps in parallel
to improve performance. This results in the console output sometimes being a bit
messy. Sorry!

### Step 6 - Start your ec2 instances

Creating a cluster only instantiates the configuration in OpsWorks. You must
start the instances in the cluster.  The process of starting an instance also
does a deploy, per the [OpsWorks default lifecycle
policies](https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-events.html).

    ./bin/rake stack:instances:start

You can watch the process via `./bin/rake stack:instances:list` or (better) via
the AWS web console. Starting the entire cluster takes about 30 minutes the
first time as the new instances will apply a dist-upgrade and possilbe reboot.
Subsequent instance restarts go significantly faster.

Opencast is started automatically, and instances start in the correct order
to ensure dependent services are available for a properly provisioned cluster.

### Step 7 - Log in!

Find the public hostname for your admin node and visit it in your browser.  Log
in with the password you set in your cluster configuration.

### Other

    # List the cluster-specific tasks available
    ./bin/rake -T

    # Read detailed help about a set of rake tasks (i.e. "cluster" related tasks).
    ./bin/rake -D cluster

    # Read detailed help about a specific rake task
    ./bin/rake -D cluster:switch

    # Switch into an already existing cluster
    ./bin/rake cluster:switch

    # Create a new cluster
    ./bin/rake cluster:new

    # Edit the currently active cluster config with the editor specified in $EDITOR
    # This also pushes relevant changes to the active cluster, layers and app in AWS -
    # for instance the revisions used for the custom chef repo and/or the application.
    # This is recommended way to edit your cluster config.
    # DO NOT EDIT YOUR STACK NAME. IT WILL CAUSE MANY, MANY PROBLEMS.
    ./bin/rake cluster:edit

    # See info about the currently active cluster
    ./bin/rake cluster:active

    # ssh to a public or private instance, using your defaultly configured ssh key.
    # This key should match the public key you set in your cluster config
    # You can omit the $() wrapper if you'd like to see the raw SSH connection info.
    # By default, the ssh username is your current login username (so, the value of $USER).
    # You can override this by passing in `ssh_user` to this rake target.
    $(./bin/rake stack:instances:ssh_to hostname=admin1)

    # Use an alternate secrets file, overriding whatever's set in .ocopsworks.rc
    SECRETS_FILE="./some_other_secrets_file.json" ./bin/rake cluster:configtest

    # Use an alternate config file, overriding whatever's set in .ocopsworks.rc
    # You should probably not use this unless you know what you're doing.
    CLUSTER_CONFIG_FILE="./some_other_cluster_config.json" ./bin/rake cluster:configtest

    # Deploy a new revision from the repo linked in your app. Be sure to restart
    # opencast after the deployment is complete.
    ./bin/rake deployment:deploy_app

    # Force deploy the latest app revision. This should only be useful when
    # working with chef recipe development. See the "force_deploy" action
    # in the chef deploy resource documentation for details on what this does.
    ./bin/rake deployment:deploy_app

    # Rollback to the last successful deployment. This is tricky - if a node
    # is new or has been frequently brought online / shutdown the concept of
    # "last" may not be the same on all instances.  You probably want to
    # avoid this and test your releases more thoroughly in isolated clusters.
    ./bin/rake deployment:rollback_app

    # View the status of the deployment (it'll be the first at the top):
    ./bin/rake deployment:list

    # Stop opencast:
    ./bin/rake opencast:stop

    # Restart opencast - this is not order intelligent, the instances are restarted as opsworks gets to them.
    ./bin/rake opencast:restart

    # Execute a chef recipe against a set of layers
    ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin,Engage,Workers" recipes="oc-opsworks-recipes::some-excellent-recipe"

    # Execute a chef recipe on all instances
    ./bin/rake stack:commands:execute_recipes_on_layers recipes="oc-opsworks-recipes::some-excellent-recipe"

    # Execute a chef recipe against only specific instances
    ./bin/rake stack:commands:execute_recipes_on_instances hostnames="admin1,workers2" recipes="oc-opsworks-recipes::some-excellent-recipe"

    # Check to see if your config file is up-to-date with the remotely stored authoritative config:
    ./bin/rake cluster:config_sync_check

    # We're done! Get rid of the cluster.
    ./bin/rake admin:cluster:delete

## Notes

### Do not edit your stack name

We use your stack name as a seed to calculate names for other resources -
instance profiles, VPCs, cloudformation stacks and templates, instance names,
etc. We use your stack name to interrogate the AWS APIs to find resources
related to your opsworks stack: changing your stack name will most definitely
make your life difficult in a thousand little ways. Don't do it, via
`oc-opsworks` or the AWS console.

### Chef

OpsWorks uses [chef](https://chef.io).  You configure the source of the custom
recipes in the stack section of your active cluster configuration file.
These options are pretty much passed through to
the `opsworks` ruby client. [Details
here](http://docs.aws.amazon.com/sdkforruby/api/Aws/OpsWorks/Client.html#create_stack-instance_method)
about what options you can pass through to, say, control security or the
revision of the custom cookbook that you'd like to use.

There are two options for the custom cookbook source, "s3" (the default) and "git",
and the choice of which source type to use is presented during the `cluster:new`
prompt session. See the "Deploying with pre-built cookbook and/or Opencast" section below for
details on the s3 method.

Using the default (prepackaged cookbook from s3) allows you to decouple from github and
[supermarket.chef.io](https://supermarket.chef.io), which could help your
deployments be more robust because you're eliminating third party dependencies. If you still want to
fetch directly from git, you can use a cookbook source type of "git" which looks like this:

```
{
  "stack": {
    "chef": {
      "custom_json": {...},
      "custom_cookbooks_source": {
        "type": "git",
        "url": "https://github.com/harvard-dce/mh-opsworks-recipes",
        "revision": "master"
      }
    }
  }
}
```

##### Chef log levels

To enable additional debug-level log output from chef, change the `chef_log_level` setting
in your stack's custom json to "debug".

### Cluster switching

The rake task `cluster:switch` looks for all configuration files stored in the
s3 bucket defined in `cluster_config_bucket_name` and lets you choose from
them.

When you switch into a cluster, the file `.ocopsworks.rc` is written. This file
defines the cluster you're working with.

### Using different secrets files

Given that a secrets files defines your AWS key and cluster config bucket, it's
the thing that lets you manage clusters in multiple AWS accounts. The cluster
config bucket stores the canonical cluster configurations for your specific
account.

If you want to use an alternate secrets file (and therefore clusters in a
different AWS account), pass it as an environment variable. The default is the
file `secrets.json`.


```
# Uses the default 'secrets.json'
./bin/rake cluster:switch

# Uses 'prod-secrets.json'
SECRETS_FILE=prod-secrets.json ./bin/rake cluster:switch
```

### Cluster configuration syncing

Cluster configuration files are stored in an s3 bucket defined by the
`cluster_config_bucket_name` variable in your `secrets.json`.  Before (almost)
every `rake` task, we check both that the configuration you're using is valid
and that it's up to date with the remote.

If there's a newer remote version, it's automatically downloaded and is used
immediately.

If your local version is ahead of the remote authoritative version you'll get a
chance to see the differences and then publish your local changes.

### Base secrets

If you'd like to share common secrets among your cluster configurations, create
a file named `base-secrets.json` in the bucket defined by
`cluster_config_bucket_name`. The contents of this file are included
automatically in `stack` -> `chef` -> `custom_json` during cluster creation.

See the example `base-secrets.json` file in `templates/base-secrets.json`.
This should save you some time during cluster creation. It's important that
this file have a limited ACL in s3 - `bucket-owner-full-control` is probably
right.

### NFS storage options

The default cluster configuration assumes you're using NFS storage provided by
the "Storage" layer.  If you use the default opsworks-managed storage,
`oc-opsworks` will create an NFS server on the single ec2 instance defined in
the "Storage" layer and connect the Admin, Engage, and Worker nodes to it via
autofs / automount and the `oc-opsworks-recipes::nfs-client` chef recipe.

If you'd like to use NFS storage provided by some other service - [zadara
storage](http://www.zadarastorage.com), for instance, please see
"README.zadara.md".

### SSL for the engage node

A dummy self-signed SSL cert is deployed by default to the engage node and
linked into the nginx proxy by the
`oc-opsworks-recipes::configure-engage-nginx-proxy` recipe.  The ssl certs are
configured in your cluster configuration:


```
{
  "stack": {
    "chef": {
      "custom_json": {
        "ssl": {
          "certificate": "a cert on a single line, all newlines replaced with \n",
          "key": "a key on a single line, all newlines replace with \n",
          "chain": "Ditto, only necessary if your cert uses a chain"
        }
      }
    }
  }
}
```

If you'd like to disable SSL, just set `certificate` and `key` to empty strings
or don't include this stanza at all.

### Metrics, alarms, and notifications

We add and remove SNS-linked cloudwatch alarms when an instance is stopped and
started. These alarms monitor (among other things) the load, available RAM and
all local disk mounts for free space.  You can subscribe to get notifications
for these alarms in the amazon SNS console under the topic named for your
cluster.

### Monitoring

[Ganglia](http://ganglia.sourceforge.net) provides very deep instance-level
metrics automatically as nodes are added and removed. You can log in to ganglia
with the username / password set in your `secrets.json` configuration. The url is
`<your public admin node hostname>/ganglia`.

### Deploying to a different region

By default, clusters are deployed to `us-east-1`. If you'd like to use a
different region:

1. Run `./bin/rake cluster:new` to generate your cluster config

1. Change the `region` via `./bin/rake cluster:edit`.

You must do this before creating your cluster via `./bin/rake admin:cluster:init`.

### SMTP via amazon SES

If you're starting from scratch, you need to create SMTP credentials in the SES
section of the AWS console. Then use these values to populate the `stack` ->
`chef` -> `custom_json` -> `smtp_auth` stanza of your `secrets.json` file.  If
you're starting with an existing `secrets.json`, this has probably already been
done for you.

You also need to verify the `default_email_sender` address in the amazon SES
console. This means the `default_email_sender` must be deliverable to pick up
the verification message.

This is not automated, but the credentials for the very limited SES user can be
shared across regions in multiple clusters without incident. If you want to
send from multiple `default_email_sender` addresses, though, say to segment
email communication by cluster, you'll need to verify each address before
using.

### s3 distribution layer

Clusters by default publish video files to an s3 bucket named after the
cluster. This s3 bucket can be used to deliver files directly or to seed a
cloudfront distribution.

### Cloudfront support

This is currently a manual process, as generally you only want production and
staging clusters to have cloudfront distribution.  Start by creating a
cloudfront distribution with the external hostname of your cluster's s3
distribution bucket for both the "origin domain name" and "origin id".

Once you've got your cloudfront domain, you include a key in your stack's
`custom_json` to have opencast deliver assets over cloudfront:


```
{
  "stack": {
    "chef": {
      "custom_json": {
        "cloudfront_url": "yourcloudfrontdistribution.example.com"
      },
    }
  }
}
```

You'll need to deploy to ensure the new cloudfront url is used.

### Live streaming support

If you're using the DCE-specific opencast release, you should have live
streaming support by default. Update the streaming-related keys in your cluster
configuration with the appropriate values before provisioning your cluster.
These keys include `live_streaming_url` and `live_stream_name` and are
used in the various `deploy-*` recipes.

### MySQL backups

The MySQL database is dumped to the `backups/mysql` directory on your nfs mount
every day via the `oc-opsworks-recipes::install-mysql-backups` recipe. This
recipe also adds a cloudwatch metric and alarm to ensure the dumps are
happening correctly.

You can tweak the hour/minute of the hour the dumps run by setting:


```
{
  "stack": {
    "chef": {
      "custom_json": {
        "mysql_dump_minute": 5
        "mysql_dump_hour": 5
      },
    }
  }
}
```

The default is 3:02am.

This means we're not using the default snapshot backups provided by RDS - this is to
save money and it make it easier to coordinate a database dump with a
filesystem snapshot. This may change at some point in the future.

In addition to these self-managed backups, our RDS clusters also maintain a daily, 1-day
window snapshot backup and a 24-hour [Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html) window.

### Static ffmpeg installation

Currently we support the ffmpeg encoder through the use of a customized build.
See [this repository](https://github.com/harvard-dce/ffmpeg-build) for how
we're building ffmpeg.

1. Create an ffmpeg. Upload it to the bucket linked to your
   `shared_asset_bucket_name` with a name matching the pattern
   `ffmpeg-<ffmpeg_version>-static.tgz`. This is done automatically by the repo
   linked above.

1. Update the `ffmpeg_version` opsworks stack `custom_json` value to the
   `ffmpeg_version` that you used above - 2.7.2, 2.8, etc.

1. Run the recipe "oc-opsworks-recipes::install-ffmpeg" on instances of concern
   to re-deploy a new ffmpeg.  If everything is set up properly, ffmpeg will be
   installed the first time an instance starts as well.

1. Ensure your opencast `config.properties` points to the correct path -
   `/usr/local/bin/ffmpeg`. This is configured automatically in
   `oc-opsworks-recipes`.


### Horizontal worker scaling

See [README.horizontal-scaling.md](README.horizontal-scaling.md).


### Custom engage and admin node hostnames

Update your stack's custom json to include two keys:


```
{
  "stack": {
    "chef": {
      "custom_json": {
        "public_engage_hostname": "engage.example.com",
        "public_admin_hostname": "admin.example.com"
      },
    }
  }
}
```

These hostnames will be used as the custom engage or admin node hostnames - you
should ensure they're set up as a CNAME back to your auto-generated aws public
hostname or possibly the EIP.  If you're using SSL for your engage node, make
sure your cert matches the `public_engage_hostname` you use here.

If you don't set either of these keys, we'll use the auto created AWS public
DNS and glue everything together for you.

### Ubuntu 14.04 Enhanced networking

The combination of the latest M5/C5 instances + the `linux-aws` v4 Linux kernel
gets us optimized networking performance out of the box. (Note: we used to
have to build a custom kernel module to get this).

The amazon enhanced networking driver doubles multithreaded / multiprocess IO from
around 5Gbps to 10Gbps and seems to have no deterimental effect on single
threaded IO. Note that actually acheiving 10Gbps is dependent on instance
placement and per AWS can only be guaranteed with the use of Placement Groups.

A useful technique for benchmarking / confirming enhanced networking can be found [here](https://aws.amazon.com/premiumsupport/knowledge-center/network-throughput-benchmark-linux-ec2/).

### Using a custom AMI for faster and more robust green instance deploys

We've built tooling to create custom AMIs for faster and more robust green
instance deploys. This tooling requires the official python aws-cli and that it
be connected to a user with the appropriate rights.

By default, new clusters will be configured to use the most recent AMIs in
the respective AWS account that have been tagged thusly:

    mh-opsworks: 1
    released: 1

We create 2 amis for each region - a public and private instance AMI.  The
process is relatively simple:

* Generate a stack via `cluster:new` that uses the `ami_builder` cluster
  variant.
* Edit the stack via `cluster:edit` and change the region, if necessary. See
  "Supporting a new region" if you're deploying somewhere other than
  `us-east-1` for the first time before working with custom AMI building.
* Run `./bin/rake admin:cluster:init stack:instances:start` to provision the
  ami builder stack and build the custom AMI seed instances.
* Log into each of the instances via `stack:instances:ssh_to` to accept the ssh
  host verification messages and make additional customizations (these should
  be done via chef, obviously).
* Run the ami builder script included in this repository -
  `./bin/build_ami.sh [profile]`. It uses the python aws-cli and bash to prepare and then
  create the AMI images. Pass in an aws credential profile if the correct
  access / secret key isn't in the default one.
* Wait. It takes around 15 minutes to create the AMIs.

Once the AMIs are created in the region of concern, you should deploy a test
clusters using these images before "releasing" them. Edit your stack's `custom_json` and update the
following keys to the ids of your newly created AMIs:


```
{
  "stack": {
    "chef": {
      "custom_json": {
        "base_private_ami_id": "ami-XXXXXX",
        "base_public_ami_id": "ami-XXXXXX"
      }
    }
  }
}
```

Once you're satisfied update the `released` tag for each AMI to "1" and they will
be picked up automatically on new cluster creation.

If you're deploying multiple clusters in a
bunch of different regions you'll need to manually edit the AMI ID when
switching regions.

The `./bin/build_ami.sh` performs some destructive actions and so can be run only once. To redo or reuse the cluster in the future you must delete the instances and run `./bin/rake stack:instances:init` to create new ones. You can then proceed as above with the `stack:instances:start` command.

### RDS Aurora Cluster

Opencast clusters built via `mh-opsworks` utilize an [RDS Aurora Cluster](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/index.html), an AWS-tuned,
drop-in replacement for standard MySQL (or Postgres). An Aurora cluster consists of
one or more RDS instances and a shared "cluster volume", which is a virtual storage layer
that spans multiple availability zones.

### Potentially problematic aws resource limits

The default aws resource limits are listed
[here](https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html).

Every oc-opsworks managed cluster provisions:

* A vpc (via Cloudformation)
* A RDS Cluster (via Cloudformation)
* An opsworks stack,
* A cloudformation stack, and
* An internet gateway

among numerous other resources. This may change in future releases.

For now, you should ensure the following limits are raised to equal the number
of clusters you'd like to deploy in your account.

* VPCs per region,
* Cloudformation Stack limit per region,
* Elastic IPs - each cluster uses three, and
* Opsworks Stack Limit for the entire account, not limited per region.

Fortunately error messages are fairly clear when a resource limit is hit,
either in the shell output of oc-opsworks or in the aws web cloudformation (or
other) UIs.

### Custom Tags

You can run `rake cluster:edit` to add or change tags in the custom json section.

```
{
  "stack": {
    "chef": {
      "custom_json": {
        ...
        "aws_custom_tags": [
            {"key": "OU", "value": "DE"},
            {"key": "Project", "value": "MH"}
        ],
      },

      ...

      }
    }
  }
}

```

Tags are applied to VPCs, RDS instance, and S3 buckets, when you do `rake
admin:cluster:init` (when these resources are created). EC2 instances and EBS
volumes have tags applied when the Opsworks stack is first brought up as the
instances and volumes don't actually exist prior to that.

For bulk management of tags or re-tagging please use the AWS [Tag Editor](https://console.aws.amazon.com/resource-groups/tag-editor/find-resources) console.

### Configtest Override

For advanced edge-case use, i.e., *if you really know what you're doing*, you can override
the automatic cluter config sanity checking by adding the following to your custom
json block:

    "skip_configtest": true

This would be useful in a situation where, for example, you wanted to create a stack
that contained only an **Analytics** node. Without this setting the rake task will fail,
complaining about a missing Admin layer.

### Security Groups

The Cloudformation stack generated during new cluster creation contains several secruity
groups that are applied to the Opsworks layers based on their reponsibilities. Some of the
secruity group rules are based on IP ranges that must be configured in your `secrets.json`
file. See the comments in `templates/base-secrets.json` for details.

The list of generated security groups is:

* OpsworksLayerSecurityGroupAdmin
* OpsworksLayerSecurityGroupAnalytics
* OpsworksLayerSecurityGroupCommon
* OpsworksLayerSecurityGroupEngage
* OpsworksLayerSecurityGroupUtility

The **OpsworksLayerSecurityGroupCommon** group will be attached to all instances in the
cluster and opens all traffic on ports 0-65535 from internal IPs and the IPs listed in
your `secrets.json` `vpn_ips` setting. This group is also attached to the RDS instance to
indicate that all instances with the common group are allowed to access RDS.

The **OpsworksLayerSecurityGroupAdmin** group additionally opens ports 80, 443 and 8080 to IPs listed
in your `secrets.json` `ca_ips` setting (capture agent IPs).

The **OpsworksLayerSecurityGroupEngage** group opens ports 80 and 443 to the world.

The **OpsworksLayerSecurityGroupUtility** group opens port 3128 (squid) to internal IPs.
If the cluster is using a [zadara](README.zadara.md) vpsa, the IP of the vpsa must be
manually added to this group.

The **OpsworksLayerSecurityGroupAnalytics** does not at this time open additional ports.

### VPC Peering

The stack's VPC initialization process with establish [VPC peering connections](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html) with any VPCs configured in the stack's custom json. Peering connections will be created and accepted, and the corresponding route table entries will be created for all subnets in both VPCs. These connections allow instances in the cluster's stack to communicate with private instances/services running in other VPCs, e.g. the transcript indexing service.

Example config:
```json
"peer_vpcs": [
  {
    "id": "vpc-01bedf8697d350f88",
    "_comment": "transcript indexer"
  },
  {
    "id": "vpc-0bb7db58996577205",
    "_comment": "some other vpc"
  }
],
```

To add peering connections to an existing cluster/VPC, add the `peer_vpcs` configuration to the cluster config's custom json and run `./bin/rake vcp:init`

### Deploying with pre-built cookbook and/or Opencast

By default the Opsworks deployment of the Opencast "app" will check out the revision specified in your cluster config (`app.app_source.revision`) and run the `mvn` command to build the jars from source. This can result in deployment failures if the maven build has trouble fetching dependencies. As an alternative, we can deploy pre-built artifacts created by an AWS CodeBuild project from an s3 bucket.

A valid configuration for using the prebuilt Opencast artifacts looks like this:

```
{
  "stack": {
    "chef": {
      "custom_json": {
        ...
        "oc_prebuilt_artifacts": {
          "enable": "true",
          "bucket": "opencast-codebuild-artifacts"
        },
        ...
      },
    }
  }
}
```

The `oc_prebuilt_artifacts` settings need to be a part of your `custom_json` block.

- `enable` turns on the use of prebuilt Opencast
- `bucket` is the name of the bucket where all the artifacts are created

If `oc_prebuilt_artifacts.enable` is "true", when you save+exit from a `cluster:edit` command, the cluster config sanity checking will verify that your configured bucket and the necessary artifacts exist. The artifacts are expected to exist at an s3 location like

`s3://[bucket name]/opencast/[branch or tag]/[node profile].tgz`

where `node_profile` is one of "admin", "presentation" or "worker". The validation check will complain with a WARNING if the bucket or any expected objects are missing.

If use of prebuilt artifacts is enabled, at deploy time the deployment recipes in mh-opsworks-recipes will fetch and extract the gzipped tar archives into the `current_deploy_root` location instead of running maven. The archives contain the complete distribution, including compiled jar files. Everything else works the same, e.g. the `current` symlink will point to the new release path, configuration files and templates will be processed, etc.

##### Pre-built cookbook

If the following are true...

- Your `custom_cookbooks_source.type` is set to "s3"
- Your `oc_prebuilt_artifacts.bucket` value is set

then your Opsworks stack wil look for the prepackaged cookbook in the `bucket` defined in the `oc_prebuilt_artifacts` settings.

If only the cookbook source type is set to "s3" then the stack will look for the prepackaged cookbook in the cluster's shared assets bucket. In both cases the archive
must be named named according to the recipe repo tag or branch specified in the
"revision" setting. The archive is assumed to be the result of running the
Berkshelf `package` command. [More info here](http://docs.aws.amazon.com/opsworks/latest/userguide/best-practices-packaging-cookbooks-locally.html).

DCE uses a combination of AWS services, including Lambda and CodeBuild, and a Github
webhook to provide an automated build pipeline for our [mh-opsworks-recipes](https://github.com/harvard-dce/mh-opsworks-recipes) cookbook.
That project can be found at [harvard-dce/mh-opsworks-builder](https://github.com/harvard-dce/mh-opsworks-builder).

## TODO

* Automate cloudfront distribution creation
* Automate external fqdn assignment to engage and admin nodes

## Contributing or reporting problems

1. Open a github issue to discuss your problem or feature idea.
1. Fork this repo.
1. Make sure tests pass: `./bin/rspec spec/`
1. Submit a pull request.

## See Also

* [OpsWorks API reference](http://docs.aws.amazon.com/opsworks/latest/APIReference/Welcome.html)
* [Aws ruby sdk](http://docs.aws.amazon.com/sdkforruby/api/Aws.html)
* [OpsWorks docs](http://docs.aws.amazon.com/opsworks/latest/userguide/welcome.html)
* Just starting out with ruby? [Just enough ruby for chef](https://docs.chef.io/ruby.html) | [try ruby](http://tryruby.org) | [beginners guide to ruby](https://hackhands.com/beginners-guide-ruby/)
* See the [chef overview](http://docs.chef.io/chef_overview.html)
* [Opsworks Cookbooks 101](https://docs.aws.amazon.com/opsworks/latest/userguide/cookbooks-101.html)

## Contributors

* Dan Collis-Puro - [djcp](https://github.com/djcp)
* Jay Luker - [lbjay](https://github.com/lbjay)

## License

This project is licensed under the same terms as [the ruby aws-sdk
itself](https://github.com/aws/aws-sdk-ruby/tree/master#license).

## Copyright

2015 President and Fellows of Harvard College
