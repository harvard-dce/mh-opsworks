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
* Tagged matterhorn logging to [loggly](http://loggly.com),
* A set of high-level rake tasks designed to make managing your OpsWorks matterhorn cluster easier,
* A way to switch between existing clusters to make collaboration easier.

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
IAM cluster manager user might be "janesmith" while your stack SSH username
would be "jane".

### Step 2 - Install mh-opsworks

You must have ruby 2 installed, ideally through something like rbenv or rvm,
though if your system ruby is >= 2 you should be fine. `./bin/setup` installs
prerequisites and sets up an empty `secrets.json`.

    git clone https://github.com/harvard-dce/mh-opsworks mh-opsworks/
    cd mh-opsworks
    ./bin/setup # checks for dependencies and sets up template env files

The base scripts (`rake`, mostly) live in `$REPO_ROOT/bin` and all paths below
assume you're in repo root.

### Step 3 - Choose (or create) your configuration files.

First, be sure you have a `secrets.json` with the correct values in it. The
most important ones are `access_key_id`, `secret_access_key`,
`shared_asset_bucket_name`, and `cluster_config_bucket_name`. This file lives
in the root of the repository by default.

Once you've set up your `secrets.json` correctly, you can start working with
clusters.

If you'd like to work in an existing cluster, run:

    ./bin/rake cluster:switch

If you'd like to create a new cluster entirely, run:

    ./bin/rake cluster:new

and follow the prompts.

Be sure to set up the "users" stanza with your desired SSH username, rights,
and public key.  Following the example set in Step 1, it'd be "jane".

It's easiest if your SSH user matches your default local unix username as
the `stack:instances:ssh_to` rake task will work out of the box.

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
first time because you're installing a bunch of base packages.  Subsequent
instance restarts go significantly faster.

### Step 7 - Start matterhorn

We've built chef recipes to manage cluster-wide matterhorn startup and
shutdown, so we'll use the "execute recipe" facilities built into OpsWorks to
start matterhorn on the relevant instances - Admin, Engage, and Workers.

    ./bin/rake matterhorn:restart

The "mh-opsworks-recipes::restart-matterhorn" recipe (run under the covers by
the `matterhorn:start` rake task) is safe for both cold starts and warm
restarts.

You can also start matterhorn via the OpsWorks web UI under "Stack -> Run
Command". Select the correct instances, choose "Execute Recipes" and enter
"mh-opsworks-recipes::restart-matterhorn". The rake task above does essentially
the same thing, but with more precision.

### Step 8 - Log in!

Find the public hostname for your admin node and visit it in your browser.  Log
in with the password you set in your cluster configuration files.

### Other

    # List the cluster-specific tasks available
    ./bin/rake -T

    # Switch into an already existing cluster
    ./bin/rake cluster:switch

    # Create a new cluster
    ./bin/rake cluster:new

    # Edit the currently active cluster config with the editor specified in $EDITOR
    # This also pushes relevant changes to the active cluster and app in AWS -
    # for instance the revisions used for the custom chef repo and/or the application.
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
    CLUSTER_CONFIG_FILE="./some_other_cluster_config.json" ./bin/rake cluster:configtest

    # Deploy a new revision from the repo / branch linked in your app. Be sure to restart
    # matterhorn after the deployment is complete.
    ./bin/rake deployment:deploy_app

    # View the status of the deployment (it'll be the first at the top):
    ./bin/rake deployment:list

    # Stop matterhorn:
    ./bin/rake matterhorn:stop

    # Start matterhorn
    ./bin/rake matterhorn:start

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
        "url": "https://github.com/harvard-dce/mh-opsworks-berkshelf",
        "revision": "master"
      }
    }
  }
}
```

### Cluster switching

The rake task `cluster:switch` looks for all configuration files stored in the
s3 bucket defined in `cluster_config_bucket_name` and lets you choose from
them.

When you switch into a cluster, the file `.mhopsworks.rc` is written. This file
defines the cluster and secrets file you're working with.

The order of cluster config (and secrets.json) file location resolution is:

- If you define `CLUSTER_CONFIG_FILE` or `SECRETS_FILE` ENV on the command
  line, they take precedent.
- The config in `.mhopsworks.rc` is next, and finally
- If the cluster config or secrets file location isn't found in the environment
  or in `.mhopsworks.rc`, they default to `templates/cluster_config_default.json.erb` or
  `secrets.json`.  The default cluster config template does not work and shouldn't be used.

The best way to deal with cluster switching is to use `cluster:new` and
`cluster:switch`.

### Cluster configuration syncing

Cluster configuration files are stored in an s3 bucket defined by the
`cluster_config_bucket_name` variable in your `secrets.json`.  Before (almost)
every `rake` task, we check both that the configuration you're using is valid
and that it's up to date with the remote.

If there's a newer remote version, it's automatically downloaded and is used
immediately.

If your local version is ahead of the remote authoritative version you'll get a
chance to see the differences and then publish your local changes.

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
configured in your `secrets.json`:


```
{
  "stack": {
    "secrets": {
      "ssl": {
        "certificate": "a cert on a single line, all newlines replaced with \n",
        "key": "a key on a single line, all newlines replace with \n",
        "chain": "Ditto, only necessary if your cert uses a chain"
      },
    }
  }
}
```

If you'd like to disable SSL, just set `certificate` and `key` to empty strings.

### Metrics, alarms, and notifications

We add and remove SNS-linked cloudwatch alarms when an instance is stopped and
started. These alarms monitor the load, available RAM and all local disk
mounts for free space.  You can subscribe to get notifications for these alarms
in the amazon SNS console under the topic named for your cluster.

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

### Loggly

The Admin, Engage, and Workers layers include a chef recipe to add an rsyslog
drain to loggly for matterhorn logs. Update `secrets.json` to add your loggly
URL and token, and ensure matterhorn is logging to syslog.

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
remove the "loggly" stanza from `secrets.json`.

### SMTP via amazon SES

If you're starting from scratch, you need to create SMTP credentials in the SES
section of the AWS console so you can populate the `stack` -> `secrets` ->
`smtp_auth` stanza of your `secrets.json` file.  If you're starting with an
existing `secrets.json`, this has probably already been done for you.

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

### Cloudfront support

This is currently a manual process, as generally you only want production and
staging clusters to have cloudfront distribution.  Start by creating a
cloudfront distribution with the external hostname of your engage node for both
the "origin domain name" and "origin id". The path should be "/static".

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

### Live streaming support

If you're using the DCE-specific matterhorn release, you should have live
streaming support by default. Update the streaming-related keys in your
`secrets.json` with the appropriate values before provisioning your cluster.

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

* VPCs per region
* Internet gateways per region
* Cloudformation Stack limit
* Opsworks Stack Limit

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
