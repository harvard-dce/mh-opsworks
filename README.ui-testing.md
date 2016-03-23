# Ghost Inspector Testing

Run [Ghost Inspector](http://ghostinspector.com/) tests on your `mh-opsworks` cluster using the `./bin/mh_ghost` script. This script acts as a wrapper around the ghost inspector commands provided by the
[mh-ui-testing](https://github.com/harvard-dce/mh-ui-testing) command-line tool. It can be used to execute test suites or individual tests. The hostnames, auth settings of your cluster, as well as your ghost inspector api key, will be automatically injected into the calls made to the ghost inspector API.

### Usage

The basic invocation looks like:

`./bin/mh_ghost [node] [options]`

where `[node]` is one of `admin1`, `engage1`, etc., and `[options]` must at least specify one of `--test=[test id]` or `--suite=[suite id]`. Test and suite ids can be obtained from Ghost Inspector: copy/paste from either the test/suite URL in your browser, or from the "API Access" links available in the lower-right section of the test/suite overview page.

#### API key

`mh_ghost` can automatically find and insert your Ghost Inspector API key from one of two places:

##### `secrets.json`

    {
      "access_key_id": "...",
      "secret_access_key": "...",
      "cluster_config_bucket_name": "my-cluster-configs",
      "ghostinspector_key": "[api key]"
    }

##### Environment variable

e.g., in your `.bashrc` file put:

    export GHOSTINSPECTOR_KEY=[api key]

##### Command-line OPTIONS

You can also provide the api key value on the command-line:

    ./bin/mh_ghost --test=[test id] --key=[api key]

#### Additional options

To see a full list of options, run `./bin/mh_ghost --help`. **Note**: while the options shown by `--help` are correct, the command invocation shown will be for the wrapped `mh-ui-testing` command. Just remember to replace `mh gi exec` with `./bin/mh_ghost`.

    Usage: mh gi exec [OPTIONS]

      Execute tests

      Options:
        --runners INTEGER  num tests to run concurrently [default: 4]
        -H, --host TEXT    host/ip of remote admin node
        --var TEXT         extra test variable(s); repeatable
        --key TEXT         ghost inspector API key
        --suite TEXT       ID of a ghost inspector suite
        --test TEXT        ID of a ghost inspector test
        --help             Show this message and exit.


### Test variables

By default `./bin/mh_ghost` will pass the following test variables to the Ghost Inspector API call:

* admin_user
* admin_pass
* target_host

Additional variables can be included in the API execution request by using the `--var` option. The format is:

    `--var name=value`

You can pass as many extra `--var` options as the test/suite expects.

### Parallel execution

Up to `n` tests can be executed concurrently, where `n` is the value of the `--runners` option. By default, `--runners` will get the number of cpus on your local machine / 2.

For example, if you have a suite containing 6 tests and the computer you are executing the tests from has 4 cpus, the test runner will create and distribute the tests to 2 concurrent subprocesses.

## Development notes

The `mh-ui-testing` tool is installed during `./bin/setup` along with a python virtualenv (at `./.venv`).

The `mh-ui-testing` release tag to install is defined in `./bin/setup` but alternate versions can be installed by calling `pip` directly:

    .venv/bin/pip install -U --force-reinstall mh-ui-testing==[version]

or:

    .venv/bin/pip install -U -e /path/to/local/mh-ui-testing

or:

    .venv/bin/pip install -U git+https://github.com/harvard-dce/mh-ui-testing.git@branch-or-sha
