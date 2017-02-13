# Local opsworks development

This feature allows you to spin up clusters that match our deployed opsworks
clusters very closely in a local vagrant environment.

We do not currently support all-in-one nodes, but that should be coming soon.

## Requirements

* virtualbox 5.0.x
* vagrant 1.8.x
* [vagrant-hosts plugin](https://github.com/oscar-stack/vagrant-hosts)
* oc-opsworks-recipes and dce-opencast must be checked out as sibling
  directories of this repository.

## Getting started

* Install the required versions of vagrant and virtual box
* Install the vagrant-hosts plugin:

        vagrant plugin install vagrant-hosts --plugin-version 2.6.2

* Ensure your repository directory structure looks like this:

        [parent dir]
          - oc-opsworks
          - oc-opsworks-recipes
          - dce-opencast

* Ensure dce-opencast and oc-opsworks-recipes are in the state you want
  to test.
* Start your environment! This takes about 20 to 25 minutes on my beefy machine
  with SSD.

        # Start an all-in-one node on http://10.10.10.50/
        ./bin/all_in_one up
        # Start a multi-node cluster on http://10.10.10.10/
        ./bin/local_cluster up

* Access your environment by pointing your web browser to the ip address above.
  The default username / password combo is "admin" / "fakepass".
* Suspend your environment when you're done to save cluster state to disk and 
  free up your RAM.

        ./bin/all_in_one suspend
        # or for a multi-node cluster
        ./bin/local_cluster suspend

* Ready to work again?

        ./bin/all_in_one resume
        # or for a multi-node cluster
        ./bin/local_cluster resume

* ssh into a node

        vagrant ssh all-in-one
        # or for a multi-node cluster
        vagrant ssh admin
        vagrant ssh local-support
        vagrant ssh engage
        vagrant ssh workers

## `./bin/all_in_one` or `./bin/local_cluster`

These harnesses help you spin up an all-in-one or multi-node cluster. Run them
without arguments to see what they support. They ultimately use the `vagrant`
command under the covers for most actions, but in the case of the multi-node
cluster it parallelizes some processes for speed.

## More info

By default we set up 4 nodes in a multi-node cluster:

* 10.10.10.2: local-support1 - the nfs share and database server
* 10.10.10.10: admin1
* 10.10.10.20: engage1
* 10.10.10.30: workers1

For an all-in-one cluster, we set up a single node:

* 10.10.10.50: all-in-one1

* We take 40% of your system RAM and allocate it to vagrant.  This will
  hopefully be enough RAM to run opencast with acceptable performance. If it
  isn't, please procure more RAM. See the `Vagrantfile` for more details.

* For a multi-node cluster, logs are available on a per-node basis under
  `log/*.log`.  All-in-ones just emit the vagrant logs to the terminal.

* You should resume / suspend clusters via the following commands, which is
  significantly faster than a `halt` and `up` combo.

        ./bin/all_in_one suspend
        ./bin/all_in_one resume
        # or for a multi-node cluster
        ./bin/local_cluster suspend
        ./bin/local_cluster resume

* Your local dce-opencast and chef recipe repos are available in the
  vagrant machines at:

        /vagrant/dce-opencast
        /vagrant/oc-opsworks-recipes

* Do work locally. After you've done stuff, redeploy your changes. This takes
  around 5 minutes (for now). See 'More on deploys' below for info on how to do
  smaller, faster builds of only specific jars.

        ./bin/all_in_one deploy
        # or for a multi-node cluster
        ./bin/local_cluster deploy

* Need to run a shutdown all your vagrant stuff? Generally, you want to suspend
  / resume on a day-to-day basis.

        ./bin/all_in_one halt
        # or for a multi-node cluster
        ./bin/local_cluster halt

* Destroy your nodes

        ./bin/all_in_one destroy
        # or for a multi-node cluster
        ./bin/local_cluster destroy

`resume` only works correctly to restore nodes that've been previously
`suspend`ed. You can't `resume` to start new nodes and expect it to work
because the provisioners don't run.

Review the `Vagrantfile` in this repo for more information on instance scaling
and other vagrant attributes.

## More on deploys

You don't have to use the deploy tooling in `local_cluster` or `all_in_one` if
you're testing changes to only a few jars.  The workflow to do more targetted
(and faster) maven builds might look like:

* Edit your code in eclipse or your editor of choice. It is automatically
  synced to `/vagrant/dce-opencast`.
* Connect to the vagrant machine that activates the jar you're modifying via
  `vagrant ssh [node name]`.
* `cd` into `/vagrant/dce-opencast` and build the jar using your normal
  maven build process. Copy or build it into the correct directory under
  `/opt/opencast/current/`
* Restart opencast via a normal ol' `sudo service opencast restart`.

## Building a new base image via packer

The base image is what all nodes are built from and include a bunch of
pre-installed software to save time.

Building the base image is handled in our
[opsworks-vm](https://github.com/harvard-dce/opsworks-vm) fork, which uses
packer.  The base image you create from that project includes the provisioning
and deploy harnesses on every vagrant image that're invoked in the
`Vagrantfile` and exercised in the `./bin/local_cluster` tooling.

After you've created a base image, upload it to our s3 bucket and register it
in Hashicorp's atlas to make it available to others.

## Known issues

* In a multie-node cluster, not a lot is printed to console during instance
  provisioning - all that stuff goes into the logs under `log/*log`.
* First time instance provisioning seems to be the most likely thing to fail,
  and it seems to fail when attaching the local shared directories.  I have
  found this to be more likely to happen when your system is under load. Somewhat
  cryptic error messages will be emitted to the console when first time node init
  errors happen. Look in `log/box-init.log` for a multi-node cluster (or directly
  in your terminal for an all-in-one)) to figure out which instance might've
  failed. You can fix this in a fairly targetted way if you understand vagrant,
  but it might be easiest to just destroy and try again. Once the first time
  provisioning succeeds, the clusters appear to be pretty reliable.
