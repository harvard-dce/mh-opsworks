# mh-opsworks

An amazon [opsworks](https://aws.amazon.com/opsworks/) implementation of a
matterhorn cluster.

## Requirements

* [aws-cli](https://aws.amazon.com/cli/)
* Appropriately configured aws rights and access keys
* A POSIX operating system

## Getting started

    git clone git@github.com:harvard-dce/mh-opsworks.git mh-dev-cluster/
    cd mh-dev-cluster
    ./bin/setup # checks for dependencies and sets up template env files
    # edit clusterconfig.json with your specific values
    ./bin/init-cluster
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
