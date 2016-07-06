# mh-opsworks [![Build Status](https://secure.travis-ci.org/harvard-dce/mh-opsworks.png?branch=master)](https://travis-ci.org/harvard-dce/mh-opsworks) [![Code Climate](https://codeclimate.com/github/harvard-dce/mh-opsworks/badges/gpa.svg)](https://codeclimate.com/github/harvard-dce/mh-opsworks)

An amazon [OpsWorks](https://aws.amazon.com/opsworks/) implementation of a
matterhorn cluster.

## Requirements

* Ruby 2
* Appropriately configured aws rights linked to an access key
* A POSIX operating system

## What you get

* Complete isolation for matterhorn production, staging, and development environments with environment parity,
* OpsWorks layers and EC2 instances for your admin, engage, worker, and support nodes,
* Automated monitoring and alarms via Ganglia and aws cloudwatch,
* A set of custom chef recipes that can be used to compose other layer and instance types,
* A flexible configuration system allowing you to scale instance sizes appropriately for your cluster's role,
* Security out of the box - instances can only be accessed via ssh keys and most instances are isolated to a private network,
* Automated matterhorn git deployments via OpsWorks built-ins,
* The ability to create and destroy matterhorn clusters completely, including all attached resources,
* Optional tagged matterhorn logging to [loggly](http://loggly.com),
* Optional newrelic integration,
* A set of high-level rake tasks designed to make managing your OpsWorks matterhorn cluster easier,
* A way to switch between existing clusters to make collaboration easier,
* A MySQL RDS database that's monitored with cloudwatch alarms, and
* Rake level docs for each task, accessed via "rake -D <task name>".

## Getting started

### Step 0 - Create account-wide groups and policies (aws account admin only)

Ask an account administrator to create an IAM group with the
"AWSOpsWorksFullAccess" managed policy and an inline policy as defined in
`./templates/example_group_inline_policy.json`.  Name it something like
`mh-opsworks-cluster-managers`. You only need to do this once per AWS account.

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

### Step 2 - Install mh-opsworks

You must have ruby 2 installed, ideally through something like rbenv or rvm,
though if your system ruby is >= 2 you should be fine. `./bin/setup` installs
prerequisites and sets up a template `secrets.json`.

You should fill in the template `secrets.json` with the cluster manager user
credentials you created previously and a `cluster_config_bucket_name` you'll
use for your team to store your cluster configuration files.

    git clone https://github.com/harvard-dce/mh-opsworks mh-opsworks/
    cd mh-opsworks
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

A default git url can be provided by setting `MATTERHORN_GIT_URL` in your shell.

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

This will create the VPC, opsworks stack, layers, and instances according to
the parameters and sizes you set in your cluster config. Basic feedback is
given while the cluster is being created, you can see more information in the
AWS opsworks console.

### Step 6 - Start your ec2 instances

Creating a cluster only instantiates the configuration in OpsWorks. You must
start the instances in the cluster.  The process of starting an instance also
does a deploy, per the [OpsWorks default lifecycle
policies](https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-events.html).

    ./bin/rake stack:instances:start

You can watch the process via `./bin/rake stack:instances:list` or (better) via
the AWS web console. Starting the entire cluster takes about 30 minutes the
first time.  Subsequent instance restarts go significantly faster.

Matterhorn is started automatically, and instances start in the correct order
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

    # Use an alternate secrets file, overriding whatever's set in .mhopsworks.rc
    SECRETS_FILE="./some_other_secrets_file.json" ./bin/rake cluster:configtest

    # Use an alternate config file, overriding whatever's set in .mhopsworks.rc
    # You should probably not use this unless you know what you're doing.
    CLUSTER_CONFIG_FILE="./some_other_cluster_config.json" ./bin/rake cluster:configtest

    # Deploy a new revision from the repo linked in your app. Be sure to restart
    # matterhorn after the deployment is complete.
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

    # Stop matterhorn:
    ./bin/rake matterhorn:stop

    # Restart matterhorn - this is not order intelligent, the instances are restarted as opsworks gets to them.
    ./bin/rake matterhorn:restart

    # Execute a chef recipe against a set of layers
    ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin,Engage,Workers" recipes="mh-opsworks-recipes::some-excellent-recipe"

    # Execute a chef recipe on all instances
    ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::some-excellent-recipe"

    # Execute a chef recipe against only specific instances
    ./bin/rake stack:commands:execute_recipes_on_instances hostnames="admin1,workers2" recipes="mh-opsworks-recipes::some-excellent-recipe"

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
`mh-opsworks` or the AWS console.

### Chef

OpsWorks uses [chef](https://chef.io).  You configure the repository that
contains custom recipes in the stack section of your active
cluster configuration file.  These options are pretty much passed through to
the `opsworks` ruby client. [Details
here](http://docs.aws.amazon.com/sdkforruby/api/Aws/OpsWorks/Client.html#create_stack-instance_method)
about what options you can pass through to, say, control security or the
revision of the custom cookbook that you'd like to use.


```
{
  "stack": {
    "chef": {
      "custom_json": {},
      "custom_cookbooks_source": {
        "type": "git",
        "url": "https://github.com/harvard-dce/mh-opsworks-recipes",
        "revision": "master"
      }
    }
  }
}
```

Rather than use a git repo (which is certainly simple), you can also package
your recipes into a tarball hosted on s3 - [see the opsworks docs
here](https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-installingcustom-repo.html).

This allows you to decouple from github and
[supermarket.chef.io](https://supermarket.chef.io), which could help your
deployments be more robust because you're eliminating third party dependencies.

If you're using the default
[mh-opsworks-recipes](https://github.com/harvard-dce/mh-opsworks-recipes), the
steps are:

* Check out the mh-opsworks-recipes repo.
* Check out the relevant tag, branch, or commit in the recipe repo.
* Run `berks package mh-opsworks-recipes-[commit, tag, or branch].tar.gz`.
* Upload this file to s3, making it public or ensuring your instances have
  access to it otherwise.
* Edit your cluster config to look like:


```
{
  "stack": {
    "chef": {
      "custom_cookbooks_source": {
        "type": "s3",
        "url": "https://url-to-the-s3-bucket/mh-opsworks-recipes-[commit, tag, or branch].tar.gz",
      }
    }
  }
}
```

And then proceed normally - update your chef recipes, deploy, etc. The linked
archive on s3 will be used for your custom recipes.

### Cluster switching

The rake task `cluster:switch` looks for all configuration files stored in the
s3 bucket defined in `cluster_config_bucket_name` and lets you choose from
them.

When you switch into a cluster, the file `.mhopsworks.rc` is written. This file
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
`mh-opsworks` will create an NFS server on the single ec2 instance defined in
the "Storage" layer and connect the Admin, Engage, and Worker nodes to it via
autofs / automount and the `mh-opsworks-recipes::nfs-client` chef recipe.

If you'd like to use NFS storage provided by some other service - [zadara
storage](http://www.zadarastorage.com), for instance, please see
"README.zadara.md".

### SSL for the engage node

A dummy self-signed SSL cert is deployed by default to the engage node and
linked into the nginx proxy by the
`mh-opsworks-recipes::configure-engage-nginx-proxy` recipe.  The ssl certs are
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

#### Monitoring the NAT instance

A cloudformation template is used to spin up / tear down the VPC and other
associated infrastructure.  A NAT instance is hooked up to the private subnet
to allow instances with no public IP egress routes to the world at large -
including the opsworks API (which makes the NAT instance pretty important).

We've created a cloudwatch alarm on the NAT instance against the default status
checks that EC2 creates. Be sure to subscribe to the SNS topic as described
above.

### Monitoring

[Ganglia](http://ganglia.sourceforge.net) provides very deep instance-level
metrics automatically as nodes are added and removed. You can log in to ganglia
with the username / password set in your `secrets.json` configuration. The url is
`<your public admin node hostname>/ganglia`.

### Deploying to a different region than the default of us-east-1

We currently support:

* us-east-1
* us-west-1
* us-west-2

By default, clusters are deployed to `us-east-1`. If you'd like to use a
different region:

1. Run `./bin/rake cluster:new` to generate your cluster config

1. Change the `region` to one of the supported options via `./bin/rake
   cluster:edit`.

You must do this before creating your cluster via `./bin/rake admin:cluster:init`.

### Supporting a new region

If you'd like to deploy clusters to a currently unsupported region:

1. find a NAT instance AMI in that region in the "community AMIs" section of
   the EC2 AMI marketplace. Look for `Amazon Linux AMI VPC NAT x86_64 HVM EBS`,
   for instance.

1. Update the AWSNATAMI mapping for your region in
   `templates/OpsWorksInVPC.template` with the AMI image ID you found above.

1. Edit your cluster config to use the new region

1. Run `./bin/rake admin:cluster:init`

1. Work with the cluster as usual.

Please submit a PR when you've confirmed everything works.

### New Relic

You can enable newrelic integration by including a newrelic key in your
cluster's `custom_json`.

```
{
  "stack": {
    "chef": {
      "custom_json": {
        "admin": { "newrelic": { "key": "your new relic API key for admin layer" }},
        "engage": { "newrelic": { "key": "your new relic API key for engage layer" }},
        "workers": { "newrelic": { "key": "your new relic API key for workers layer" }}
      },
    }
  }
}
```

If you omit the layer name or the "newrelic" key for a layer, newrelic isn't enabled for that layer.
All nodes in the layer will use the same key.

Chef enables newrelic app monitoring on the admin, worker and engage nodes.
Each node is monitored separately and under an aggregate app named after your
stack.

This feature requires that your maven build downloads and unpacks the correct
newrelic agent jar - this is done by default in the DCE matterhorn
distribution.

Instance-level new relic logs are stored in the same directory as your
matterhorn logs.

### Loggly

The Admin, Engage, and Workers layers include a chef recipe to add an rsyslog
drain to loggly for matterhorn logs. Update the stack's `custom_json` section
of your cluster configuration to add your loggly URL and token, and ensure
matterhorn is logging to syslog.

If you are using your cluster for dev work but you still wish to log to loggly,
consider setting up a separate ["free tier"](https://www.loggly.com/plans-and-pricing/)
loggly account.

Log entries are tagged with:

* Stack name,
* Hostname,
* Layer name, and
* A single string comprising stack and hostname.

If you don't want to log to loggly, remove the
`mh-opsworks-recipes::rsyslog-to-loggly` recipe from your cluster config and
remove the "loggly" stanza from your stack's `custom_json`.

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

### Experimental EFS support

[Amazon Elastic File System](https://aws.amazon.com/efs/) is currently in
preview and can only be deployed to the us-west-2 region.  You can create an
efs-backed cluster by selecting one of the efs variants after running
`./bin/rake cluster:new`.

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
`custom_json` to have matterhorn deliver assets over cloudfront:


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

If you're using the DCE-specific matterhorn release, you should have live
streaming support by default. Update the streaming-related keys in your cluster
configuration with the appropriate values before provisioning your cluster.
These keys include `live_streaming_url` and `live_stream_name` and are
used in the various `deploy-*` recipes.

### MySQL backups

The MySQL database is dumped to the `backups/mysql` directory on your nfs mount
every hour via the `mh-opsworks-recipes::install-mysql-backups` recipe. This
recipe also adds a cloudwatch metric and alarm to ensure the dumps are
happening correctly.

You can tweak the minute of the hour the dumps run by setting:


```
{
  "stack": {
    "chef": {
      "custom_json": {
        "run_mysql_dump_on_the": 5
      },
    }
  }
}
```

So, like your local radio weatherman, we run the mysql dump on the "5s", or the
"2s", or the "10s" or whatever. The default is `2`.

This means we're not using the default backups provided by RDS - this is to
save money and it make it easier to coordinate a database dump with a
filesystem snapshot. This may change at some point in the future.

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

1. Run the recipe "mh-opsworks-recipes::install-ffmpeg" on instances of concern
   to re-deploy a new ffmpeg.  If everything is set up properly, ffmpeg will be
   installed the first time an instance starts as well.

1. Ensure your matterhorn `config.properties` points to the correct path -
   `/usr/local/bin/ffmpeg`. This is configured automatically in
   `mh-opsworks-recipes`.

### Horizontal worker scaling

Automated horizontal worker scaling is run via a cron job on the ganglia
monitoring node (monitoring-master1). This uses [our mo-scaler](https://github.com/harvard-dce/mo-scaler) python script.

The chef recipe `mh-opsworks-recipes::install-ec2-scaling-manager` installs the
necessary python requirements, the git repository and configures a `.env` file
automatically with the necessary credentials. If you change the REST
authentication password, you should re-rerun this recipe.

If you want to use a different release tag, update `ec2_management_release` in
your stack's `custom_json` and re-run the recipe above.

The number of worker instances available at any given time is controlled by
three values that can be modified in your `custom_json` (see example below).
After updating you will need to re-run the above recipe.

```
{
  "stack": {
    "chef": {
      "custom_json": {
        "moscaler": {
          "offpeak_instances": 2,
          "peak_instances": 10,
          "weekend_instances": 1
        },
        ...
      }
    }
  }
}
```

then:

`./bin/rake stack:commands:execute_recipes_on_layers layers="Ganglia" recipes="mh-opsworks-recipes::install-ec2-scaling-manager"`

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

"Enhanced networking" allows your instances to take full advantage of 10Gbps
networking on aws. Opsworks ubuntu 14.04 instances have enhanced networking
enabled, but unfortunately use a driver too old to get full networking speed.

The `mh-opsworks-recipes::enable-enhanced-networking` recipe patches and
installs the correct driver. This doubles multithreaded / multiprocess IO from
around 5Gbps to 10Gbps and seems to have no deterimental effect on single
threaded IO.

### Using a custom AMI for faster and more robust green instance deploys

We've built tooling to create custom AMIs for faster and more robust green
instance deploys. This tooling requires the official python aws-cli and that it
be connected to a user with the appropriate rights.

We create 2 amis for each region - a public and private instance AMI.  The
process is relatively simple:

* Generate a stack via `cluster:new` that uses the `ami_builder` cluster
  variant.
* Edit the stack via `cluster:edit` and change the region, if necessary. See
  "Supporting a new region" if you're deploying somewhere other than
  `us-east-1` for the first time before working with custom AMI building.
* Edit the stack config to remove the pre-existing `base_private_ami_id` and
  `base_public_ami_id` settings, as we want to start from a clean image.
* Run `./bin/rake admin:cluster:init stack:instances:start` to provision the
  ami builder stack and build the custom AMI seed instances.
* Log into each of the instances via `stack:instances:ssh_to` to accept the ssh
  host verification messages and make additional customizations (these should
  be done via chef, obviously).
* Run the ami builder script included in this repository -
  `./bin/build_ami.sh`. It uses the python aws-cli and bash to prepare and then
  create the AMI images. Pass in an aws credential profile if the correct
  access / secret key isn't in the default one.
* Wait. It takes around 15 minutes to create the AMIs.

Once the AMIs are created in the region of concern, you can deploy other
clusters using these images. Edit your stack's `custom_json` and include the
following keys:


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

You can include this in your `base-secrets.json` to make all subsequent cluster
creations use these custom AMIs. If you're deploying multiple clusters in a
bunch of different regions you'll need to manually edit the AMI ID when
switching regions.

### RDS instance configuration

You can override default RDS instance creation parameters by adding them to the
`rds` stanza of your cluster configuration. The attributes you put in there are
`merge`d into the defaults and passed to the ruby SDK
[`Aws::RDS::Client#create_db_instance`
method](https://docs.aws.amazon.com/sdkforruby/api/Aws/RDS/Client.html#create_db_instance-instance_method).

So, by default we create a single-AZ RDS instance for all but "large" clusters.
If you wanted to create a multi-az instance for a non-large cluster, you'd run
`cluster:new`, update your cluster configuration to look something like:


```
{
  "rds": {
    "db_name": "matterhorn",
    "_other stuff . . ": "other stuff",
    "multi_az": true
  }
}
```

and then create your cluster.  This pattern is similar for other RDS-specific
attributes.

### Potentially problematic aws resource limits

The default aws resource limits are listed
[here](https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html).

Every mh-opsworks managed cluster provisions:

* A vpc
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
either in the shell output of mh-opsworks or in the aws web cloudformation (or
other) UIs.

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
