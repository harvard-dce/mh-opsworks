# mh-opsworks

An amazon [opsworks](https://aws.amazon.com/opsworks/) implementation of a
matterhorn cluster.

## Requirements

* Ruby 2
* Appropriately configured aws rights linked to an access key
* A POSIX operating system

## Getting started

    git clone git@github.com:harvard-dce/mh-opsworks.git mh-opsworks/
    cd mh-opsworks
    ./bin/setup # checks for dependencies and sets up template env files
    # edit clusterconfig.json with your specific values, or get a copy and fill in your access keys
    vim cluster_config.json

    # sanity check your cluster_config.json
    rake cluster:configtest

    # Use an alternate cluster configuration file
    CLUSTER_CONFIG_FILE="./some_other_config.json" rake cluster:configtest

    # List the cluster-specific tasks available
    rake -T

    # Initialize a VPC based on the variables defined in your default cluster_config.json
    rake vpc:init
    # Time passes, output is given

## Contributing or reporting problems

1. Open a github issue to discuss your problem or feature idea.
1. Fork this repo.
1. Make sure tests pass: `bundle exec rake`
1. Submit a pull request.

## Contributors

* Dan Collis-Puro - [djcp](https://github.com/djcp)

## License

This project is licensed under the same terms as Rails itself.

## Copyright

2015 President and Fellows of Harvard College
