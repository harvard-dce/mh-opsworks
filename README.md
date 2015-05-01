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
* A set of high-level ruby tasks designed to make managing your OpsWorks matterhorn cluster easier.

## Getting started

### Step 0 - Create and configure credentials and policies

Create or import an ec2 SSH keypair. You can do this in the AWS web console
under "EC2 -> Network & Security -> Key Pairs".  Keep the name handy because
you'll need it later in your `cluster_config.json` file. This ssh keypair
allows you to access the built-in "ubuntu" user as a backchannel for debugging.

Create an IAM group with the "AWSOpsWorksFullAccess" managed policy and an
inline policy as defined in `./templates/example_group_inline_policy.json`.
Name it something like `mh-opsworks-cluster-managers`. You'll probably need to
be an account administrator to do this. You only need to do this once per AWS
account.

This group allows a user to create / delete clusters including the VPC,
cloudformation templates, SNS topics, cloudwatch metrics and alarms and
numerous other AWS resources.

Create an IAM user and add it to the group you created above. Create an aws
access key pair for this user and have it handy.

### Step 1 - Find an unused cidr block for your cluster's VPC

Every cluster has its own VPC, and that VPC must be unique on its cidr block
and name within the aws account.  Look at the list of VPCs in the aws console
and pick a cidr block that's not currently in use large enough to contain your
public and private instances. For example, 10.1.1.0/24 gives you 254 addresses
that can then be split into public, private, and reserve ranges (for future
expansion).

VPCs do not share RFC 1918 space, but keeping cidr blocks unique makes VPC
peering easier should we want to do it in the future. The semantics of how we
split clusters across VPCs and how much we care about unique cidr blocks may
change in the future.

### Step 2 - Install mh-opsworks

You must have ruby 2 installed, ideally through something like rbenv or rvm,
though if your system ruby is >= 2 you should be fine. `./bin/setup` installs
prerequisites and sets up empty cluster configuration templates.

    git clone git@github.com:harvard-dce/mh-opsworks.git mh-opsworks/
    cd mh-opsworks
    ./bin/setup # checks for dependencies and sets up template env files

The base scripts (`rake`, mostly) live in `$REPO_ROOT/bin` and all paths below
assume you're in repo root.

### Step 3 - Create your configuration files.

You can use multiple configuration files (more on that later), but by default
`mh-opsworks` reads from `$REPO_ROOT/cluster_config.json` and
`$REPO_ROOT/secrets.json`. If you're working with a cluster that already
exists, get the correct `cluster_config.json` from the right person.

    cd mh-opsworks

    # edit cluster_config.json with your specific values
    vim cluster_config.json

    # Edit secrets to include the correct AWS (and other) credentials.
    vim secrets.json

### Step 4 - Sanity check your cluster configuration

We've implemented a set of sanity checks to ensure your cluster configuration
looks right. They are by no means comprehensive, but serve as a basic
pre-flight check. The checks are run automatically before every `rake` task.

    # sanity check your cluster_config.json
    ./bin/rake cluster:configtest

You'll see a relatively descriptive error message if there's something wrong
with your cluster configuration.

### Step 5 - Spin up your cluster

    ./bin/rake admin:cluster:init

This will create the VPC, opsworks stack, layers, and instances according to
the parameters and sizes you set in your `cluster_config.json`. Basic feedback
is given while the cluster is being created, you can see more information in
the AWS opsworks console.

### Step 6 - Start your ec2 instances

Creating a cluster only instantiates the configuration in OpsWorks. You must
start the instances in the cluster.  The process of starting an instance also
does a deploy, per the [OpsWorks default lifecycle
policies](https://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-events.html).

    ./bin/rake stack:instances:start

You can watch the process via `./bin/rake stack:instances:list` or
(better) via the AWS web console. Starting the entire cluster takes about 30
minutes the first time because you're installing a bunch of base packages.
Subsequent instance restarts go significantly faster.

### Step 7 - Start matterhorn

We've built chef recipes to manage cluster-wide matterhorn startup and
shutdown, so we'll use the "execute recipe" facilities built into OpsWorks to
start matterhorn on the relevant instances - Admin, Engage, and Workers.

    ./bin/rake stack:commands:execute_recipes layers="Admin,Engage,Workers" recipes="mh-opsworks-recipes::restart-matterhorn"

The "mh-opsworks-recipes::restart-matterhorn" recipe is safe for both cold
starts and warm restarts.

You can also start matterhorn via the OpsWorks web UI under "Stack -> Run
Command". Select the instances, choose "Execute Recipes" and enter
"mh-opsworks-recipes::restart-matterhorn".

### Step 8 - Log in!

Find the public hostname for your admin node and visit it in your browser.  Log
in with the password you set in your cluster configuration files.

### Other

    # List the cluster-specific tasks available
    ./bin/rake -T

    # ssh to a public or private instance, using your defaultly configured ssh key.
    # This key should match the public key you set in your cluster_config.json
    # You can omit the $() wrapper if you'd like to see the raw SSH connection info.
    $(./bin/rake stack:instances:ssh_to hostname=admin1)

    # You can mix-and-match secrets and configuration files in the same invocation.
    # Use an alternate cluster configuration file
    CLUSTER_CONFIG_FILE="./some_other_config.json" ./bin/rake cluster:configtest

    # Use an alternate secrets file
    SECRETS_FILE="./some_other_secrets_file.json" ./bin/rake cluster:configtest

    # Deploy a new revision from the repo / branch linked in your app. Be sure to restart
    # matterhorn after the deployment is complete.
    ./bin/rake deployment:deploy_app

    # View the status of the deployment (it'll be the first at the top):
    ./bin/rake deployment:list

    # Stop matterhorn:
    ./bin/rake stack:commands:execute_recipes layers="Admin,Engage,Workers" recipes="mh-opsworks-recipes::stop-matterhorn"

    # We're done! Get rid of the cluster.
    ./bin/rake admin:cluster:delete

## Chef

OpsWorks uses [chef](https://chef.io).  You configure the repository that
contains custom recipes in the stack section of your active
`cluster_config.json` file.  These options are pretty much passed through to
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

## Notes

## Layer instance start order

The "Storage" and "MySQL db" layers are started before all others. Once those
layers report that they are "online", every other instance is started
simultaneously. This will probably change, especially if/when we move to amazon
efs storage.

Instances are stopped in reverse layer definition order by "stack:instances:stop".

## Metrics, alarms, and notifications

We add and remove SNS-linked cloudwatch alarms when an instance is stopped and
started. These alarms monitor the load, available RAM and all local disk
mounts for free space.  You can subscribe to get notifications for these alarms
in the amazon SNS console under the topic named for your cluster.

## Monitoring

[Ganglia](http://ganglia.sourceforge.net) provides very deep instance-level
metrics automatically as nodes are added and removed. You can log in to ganglia
with the username / password set in your cluster configuration. The url is
`<your public admin node hostname>/ganglia`. The username and password is set
in your cluster configuration.

## SMTP via amazon SES

You need to verify the `default_email_sender` address in the amazon SES console
and create your credentials. This means the `default_email_sender` must be
deliverable to pick up the verification message.

This is not automated, but the credentials for the very limited SES user can be
shared across regions in multiple clusters without incident. If you want to
send from multiple `default_email_sender` addresses, though, say to segment
email communication by cluster, you'll need to verify each address before
using.

## Contributing or reporting problems

1. Open a github issue to discuss your problem or feature idea.
1. Fork this repo.
1. Make sure tests pass: `./bin/rspec spec/`
1. Submit a pull request.

## See Also

* [OpsWorks API reference](http://docs.aws.amazon.com/opsworks/latest/APIReference/Welcome.html)
* [Aws ruby sdk](http://docs.aws.amazon.com/sdkforruby/api/Aws.html)
* [OpsWorks docs](http://docs.aws.amazon.com/opsworks/latest/userguide/welcome.html)

## Contributors

* Dan Collis-Puro - [djcp](https://github.com/djcp)

## License

This project is licensed under the same terms as [the ruby aws-sdk
itself](https://github.com/aws/aws-sdk-ruby/tree/master#license).

## Copyright

2015 President and Fellows of Harvard College
