# mh-opsworks [![Build Status](https://secure.travis-ci.org/harvard-dce/mh-opsworks.png?branch=master)](https://travis-ci.org/harvard-dce/mh-opsworks) [![Code Climate](https://codeclimate.com/github/harvard-dce/mh-opsworks/badges/gpa.svg)](https://codeclimate.com/github/harvard-dce/mh-opsworks)

An amazon [OpsWorks](https://aws.amazon.com/opsworks/) implementation of a
matterhorn cluster.

## Requirements

* Ruby 2
* Appropriately configured aws rights linked to an access key
* A POSIX operating system

## Getting started

    git clone git@github.com:harvard-dce/mh-opsworks.git mh-opsworks/
    cd mh-opsworks
    ./bin/setup # checks for dependencies and sets up template env files
    # edit clusterconfig.json with your specific values
    vim cluster_config.json

    # Edit credentials to include the correct AWS credentials. Handily, we've
    # included a comment field to allow you to keep track of what credentials are
    # what.

    vim credentials.json

    # sanity check your cluster_config.json
    rake cluster:configtest

    # Use an alternate cluster configuration file
    CLUSTER_CONFIG_FILE="./some_other_config.json" rake cluster:configtest

    # Use an alternate credentials file
    CREDENTIALS_FILE="./some_other_credentials_file.json" rake cluster:configtest

    # You can mix-and-match credentials and configuration files in the same invocation

    # List the cluster-specific tasks available
    rake -T

    # Initialize a VPC based on the variables defined in your default cluster_config.json
    rake vpc:init
    # Time passes, output is given

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

Instances in layers are started in the order in which the layers are defined by
the "stack:instances:start" command.  They are stopped in reverse order by
"stack:instances:stop". This allows you to manage instance dependencies by
putting important services - say your database or nfs storage - in layers
defined early in the stack. The example `templates/cluster_config_example.json`
defines layers in the correct order.

## Contributing or reporting problems

1. Open a github issue to discuss your problem or feature idea.
1. Fork this repo.
1. Make sure tests pass: `bundle exec rspec spec/`
1. Submit a pull request.

## See Also

* [Opsworks API reference](http://docs.aws.amazon.com/opsworks/latest/APIReference/Welcome.html)
* [Aws ruby sdk](http://docs.aws.amazon.com/sdkforruby/api/Aws.html)
* [Opsworks docs](http://docs.aws.amazon.com/opsworks/latest/userguide/welcome.html)

## Contributors

* Dan Collis-Puro - [djcp](https://github.com/djcp)

## License

This project is licensed under the same terms as [the ruby aws-sdk
itself](https://github.com/aws/aws-sdk-ruby/tree/master#license).

## Copyright

2015 President and Fellows of Harvard College
