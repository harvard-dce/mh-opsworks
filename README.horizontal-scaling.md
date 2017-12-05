## Horizontal worker scaling

Automated horizontal worker scaling, when enabled, is run via a cron job on the ganglia
monitoring node (monitoring-master1). It uses [the mo-scaler](https://github.com/harvard-dce/mo-scaler)
python software to increase and decrease the number of worker nodes for a cluster
based on one of two strategies.

The chef recipe [`oc-opsworks-recipes::install-moscaler`](https://github.com/harvard-dce/mh-opsworks-recipes/blob/master/recipes/install-moscaler.rb) installs the
necessary python requirements, the git repository and generates both a `.env` file
and an `autoscale.json` config file with the necessary credentials and other variables from 
your cluster config settings. If you change any of the scaling
configuration settings (detailed below) you should re-rerun this recipe.

### Scaling Types

There are two high-level types of scaling under which **moscaler** can be run: `time` and `auto`.
The time-based scaling ensures that a fixed number of workers are online based on
the time of day and the day of the week. The `auto` scaling type tries to turn on/off 
worker nodes based on the current state of the cluster, e.g., a server load metric or
job count values reported by Opencast.

The type to be used is determined by the `moscaler_type` value in the `moscaler`
block of your cluster config. 

### Time-based

The number of worker instances available at any given time is controlled by
three values that can be modified in your `custom_json`.

#### Example config

This is an example block that would be inserted into the stack's custom json.

            "moscaler": {
              "moscaler_type": "time",
              "offpeak_instances": 2,
              "peak_instances": 10,
              "weekend_instances": 1
            },

The (currently non-configurable) time ranges for *offpeak*, *peak* and *weekend* are:

* peak: M-F, 7am-11pm
* offpeack: M-F, 11pm-7am
* weekend: 12am Sat - 12pm Sun

### Auto-scaling confguration

When using the "auto" scaling type mo-scaler can be configured to use one or more "strategies"
when determining whether to scale up or down. The two strategy methods available are `cloudwatch` 
and `queued_jobs`, with the `cloudwatch` method being preferred (see below).

Both methods make some form of calculation based on a metric related to the state of the cluster, 
and then compare the result to configured `up_threshold` and `down_threshold` values to 
determine if there should be a scale up or down event. 

If a scale up/down event is triggered mo-scaler will use the `autoscale_up_increment` and 
`autoscale_down_increment` values to know how many workers it should attempt to start/stop.

In psuedo-code it looks like this:

    IF ClusterMetric >= ScaleUpThreshold THEN

        Scale up x workers

     ELSE IF ClusterMetric < ScaleDownThreshold THEN

        Scale down x workers

Where `x` is the respective `up|down_increment` value.

#### Example config

This is an example block that would be inserted into the stack's custom json.

        "moscaler": {
          "moscaler_type": "auto",
          "moscaler_release": "v1.1.1",
          "autoscale_up_increment": 2,
          "autoscale_pause_cycles": 1,
          "autoscale_strategies": [
            {
              "method": "cloudwatch",
              "name": "mh queued jobs",
              "settings": {
                "metric": "OpencastJobsQueued",
                "instance_name": "monitoring-master1",
                "namespace": "AWS/OpsworksCustom",
                "up_threshold": 1,
                "down_threshold": 1
              }
            },
            {
              "method": "cloudwatch",
              "name": "workers layer load",
              "settings": {
                "metric": "load_1",
                "layer_name": "Workers",
                "namespace": "AWS/OpsWorks",
                "up_threshold": 10.0,
                "down_threshold": 8.0,
                "up_threshold_online_workers_multiplier": 1
              }
            }
          ]
        },

With this configuration mo-scaler would sequentially consult first the `OpencastJobsQueued` metric 
published by the `monitoring-master1` instance, and then the `load_1` metric for the entire workers
layer. The "mh queued jobs" strategy is going to recommend scaling up 2 workers if its metric is 
equal to or above the threshold of 1, or down 1 worker if there are zero queued jobs. The "workers layer load"
strategy is going to recommend scaling up at >= `10.0` and down at < `8.0`. Once all strategies have
been executed the results are used to determine the actual action. If **any** strategy results in an
"up" recommendation, mo-scaler will attempt to scale up. If **all** strategies agree that "down" is
the way to go, then mo-scaler will attempt to scale down.

Finally, should a scale up event occur, if `autoscale_pause_cycles` present and > 0, mo-scaler will
ignore future scale up events for that many cycles. (mo-scaler is assumed to be running via cron, so
a cycle means 1 execution of the auto scaling).

#### Infrequently asked questions

**Q**: what happens if `down_threshold` is actually greater than `up_threshold`? For instance, the
cluster should scale up when the worker layer's `load_5` value is greater than 8.0, but scale down when the value is
less than 10.0.

**A**: This may seem counter-intuitive, but it's most likely fine. Keep in mind that `mo-scaler` has
protections built in to prevent workers from being scaled down if they are not idle or if they haven't used up enough
of their billing hour. *A scale down event triggered by the autoscaliThis is an example block that would be inserted into the stack's custom json.ng only results in an **attempt** to scale down.
The attempt will frequently be aborted if there's not enough idle workers. Crossing that `down_threshold`
just tells `mo-scaler` to start *trying* to scale down. There is some danger of "flapping" instances up/down, so this
kind of configuration scenario should be thoroughly tested.

### Cluster config settings

The defaults for all moscaler settings are defined in a `oc-opsworks-recipes` helper function:

    def get_moscaler_info
      {
          'moscaler_type' => 'disabled',
          'moscaler_release' => 'v1.1.0',
          'moscaler_debug' => false,
          'offpeak_instances' => 2,
          'peak_instances' => 10,
          'weekend_instances' => 1,
          'cron_interval' => '*/2',
          'min_workers' => 1,
          'idle_uptime_threshold' => 50,
          'autoscale_up_increment' => 2,
          'autoscale_down_increment' => 1,
          'autoscale_pause_cycles' => 1,
          'autoscale_strategies' => []
        }.merge(node.fetch(:moscaler, {}))
    end

The configuration is admittedly confusing as some settings control aspects of provisioning vs others
that are meant for mo-scaler itself. I'll break them out based on the thing being configured.

#### settings that affect the chef recipe

* `moscaler_type`: either "time" or "auto". This is used by the `install-moscaler` recipe to determine
  what cron entries to create. Set to empty string or "disabled" to disable moscaler. 
  The recipe will still install the mo-scaler software but no cron entries will be created.
  
* `moscaler_release`: used by the `install-moscaler` recipe. This should be a git 
  branch/sha/tag from the `harvard-dce/mo-scaler` repo.

* `moscaler_debug`: enable debug log output. `mo-scaler` logs to stdout and the cron entries created 
  by the recipe redirect all output to syslog.
  
* `{offpeak,peak,weekend}_instances`: See above re: time-based scaling.

* `cron_interval`: default is to run mo-scaler every 5 minutes.

#### settings that go into mo-scaler's `.env` file

* `min_workers`: tells `mo-scaler` not to scale down fewer than this many workers.

* `idle_uptime_threshold`: how much of its "billing hour" an instance needs to have used up before
  it's a candidate for stopping
  
#### settings that end up in mo-scaler's `autoscale.json` file

* `autoscale_up_increment`: how many worker nodes to start per scale up event.

* `autoscale_down_increment`: how many worker nodes to stop per scale down event.

* `auotscale_up_threshold`: A value that the autoscaling mechanism should use to identify when to 
  scale up. Must be an integer or float.

* `autoscale_down_threshold`: Same as `autoscale_up_threshold` but for scaling down.

* `autoscale_pause_cycles`: when a scale up event occurs mo-scaler will refuse to scale up
  again for this many cycles to allow previously started workers to come online and start accepting
  workload.
 
* `autoscale_strategies`: one or more stragey configuration blocks.

For the `.env` and `autoscale.json` settings, see the README at http://github.com/harvard-dce/mo-scaler
for more info.

After updating any of these settings you will need to rerun the recipe, either via the AWS console
or `oc-opsworks`:

`./bin/rake stack:commands:execute_recipes_on_layers layers="Ganglia" recipes="oc-opsworks-recipes::install-moscaler"`

### Pausing & Resuming

There are times, partiuclarly during releases when it's necessary that all MH workers be up and online,
when it's helpful to pause the horizontal scaling. For that there are a pair of rake tasks,

    ./bin/rake moscaler:pause
    ./bin/rake moscaler:resume
    
