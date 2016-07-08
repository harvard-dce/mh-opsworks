## Horizontal worker scaling

Automated horizontal worker scaling, when enabled, is run via a cron job on the ganglia
monitoring node (monitoring-master1). It uses [the mo-scaler](https://github.com/harvard-dce/mo-scaler)
python software to increase and decrease the number of worker nodes for a cluster
based on one of two strategies.

The chef recipe `mh-opsworks-recipes::install-moscaler` installs the
necessary python requirements, the git repository and configures a `.env` file
automatically with the necessary credentials and other environment variables from 
your cluster config settings. If you change any of the scaling
configuration settings (detailed below) you should re-rerun this recipe.

### Scaling Strategies

There are two high-level strategies under which **moscaler** can be run: `time` and `auto`.
The time-based strategy ensures that a fixed number of workers are online based on
the time of day and the day of the week. The `auto` strategy tries to turn on/off 
worker nodes based on the current state of the cluster, e.g., a server load metric or
job count values reported by Matterhorn.

The stragegy to be used is determined by the `moscaler_strategy` value in the `moscaler`
block of your cluster config. 

### Time-based

The number of worker instances available at any given time is controlled by
three values that can be modified in your `custom_json`.

Example config:

    {
      "stack": {
        "chef": {
          "custom_json": {
            "moscaler": {
              "moscaler_strategy": "time",
              "offpeak_instances": 2,
              "peak_instances": 10,
              "weekend_instances": 1
            },
            ...
          }
        }
      }
    }

The (currently non-configurable) time ranges for *offpeak*, *peak* and *weekend* are:

* peak: M-F, 7am-11pm
* offpeack: M-F, 11pm-7am
* weekend: 12am Sat - 12pm Sun

### Auto-scaling

There are two types of auto scaling mechanisms available: `LayerLoad` and `HighLoadJobs`.
Only the `LayerLoad` type should be used at this time as the `HighLoadJobs` mechanism
makes use of some unreliable data from the Matterhorn statistics API.

Both types make some form of calculation based on a metric related to the state of the cluster, and then compare
the result to one or both of the `autoscale_up_threshold` and `autoscale_down_threshold` to
determine if there should be a scale up or down event. In psuedo-code it looks like this:

    IF ClusterMetric >= ScaleUpThreshold THEN

        Scale up x workers

     ELSE IF ClusterMetric < ScaleDownThreshold THEN

        Scale down x workers

Where `x` is the respective `autoscale_up|down_threshold` value.

**Question**: what happens if `scale_down_threshold` is actually greater than `scale_up_threshold`? For instance, the
cluster should scale up when the worker layer's `load_5` value is greater than 8.0, but scale down when the value is
less than 10.0.

**Answer**: This may seem counter-intuitive, but it's most likely fine. Keep in mind that `mo-scaler` has
protections built in to prevent workers from being scaled down if they are not idle or if they haven't used up enough
of their billing hour. *A scale down event triggered by the autoscaling only results in an **attempt** to scale down.`
The attempt will frequently be aborted if there's not enough idle workers. Crossing that `autoscale_down_threshold`
just tells `mo-scaler` to start *trying* to scale down. There is some danger of "flapping" instances up/down, so this
kind of configuration scenario should be thoroughly tested.

#### LayerLoad

This method scales workers up/down based on the value of an Opsworks
layer's cloudwatch metric. It compares the metric's reported values against a couple
of threshold settings and scales up or down accordingly.

Example config:

    {
      "stack": {
        "chef": {
          "custom_json": {
            "moscaler": {
              "moscaler_strategy": "auto",
              "autoscale_type": "LayerLoad"
              "autoscale_up_increment" => 2,
              "autoscale_down_increment" => 2,
              "autoscale_up_threshold" => 12.0,
              "autoscale_down_threshold" => 8.0,
              "autoscale_layerload_metric" => "load_1",
              "autoscale_layerload_sample_count" => 3
            },
            ...
          }
        }
      }
    }
    
This configuration would result in `moscaler` scaling up two workers if the `load_1` metric
for the workers layer reports a value equal to or higher than 12.0 at 60s intervals
for 3 consecutive intervals. It would attempt to scale down two workers if that same metric
was less than 8.0 for 3 consectutive intervals.

#### HighLoadJobs

Don't use this one. :)

Unfortunately the logic of the `HighLoadJobs` method uses some unreliable data from the Matterhorn
API. It's in there for reference in case we ever make Matterhorn's job dispatching behave in a way
we'd like.

### Cluster config settings

The defaults for all moscaler settings are defined in a `mh-opsworks-recipes` helper function:

    def get_moscaler_info
      {
          'moscaler_strategy' => 'disabled',
          'moscaler_release' => 'v1.0.0',
          'moscaler_debug' => false,
          'offpeak_instances' => 2,
          'peak_instances' => 10,
          'weekend_instances' => 1,
          'cron_interval' => '*/2',
          'autoscale_up_increment' => 2,
          'autoscale_down_increment' => 1,
          'autoscale_up_threshold' => 12.0,
          'autoscale_down_threshold' => 8.0,
          'autoscale_type' => 'LayerLoad',
          'autoscale_layerload_metric' => 'load_1',
          'autoscale_layerload_sample_count' => 3,
          'autoscale_layerload_sample_period' => 60,
          'min_workers' => 1,
          'idle_uptime_threshold' => 50,
          'autoscale_pause_interval' => 300
        }.merge(node.fetch(:moscaler, {}))
    end
  end

* `moscaler_strategy`: either "time" or "auto". Set to empty string or "disabled" to disable moscaler. 
  The recipe will still install the `mo-scaler` software but no cron entries will be created.
  
* `moscaler_release`: a git branch/sha/tag from the `harvard-dce/mo-scaler` repo.

* `moscaler_debug`: enable debug log output. `mo-scaler` logs to stdout and the cron entries created 
  by the recipe redirect all output to syslog.
  
* `{offpeak,peak,weekend}_instances`: See above re: time-based scaling.

* `cron_interval`: default is to run mo-scaler every 5 minutes.

* `autoscale_up_increment`: how many worker nodes to start per scale up event.

* `autoscale_down_increment`: how many worker nodes to stop per scale down event.

* `auotscale_up_threshold`: A value that the autoscaling mechanism should use to identify when to 
  scale up. Must be an integer or float.

* `autoscale_down_threshold`: Same as `autoscale_up_threshold` but for scaling down.

* `autoscale_type`: identifies which autoscaling mechanim to use. The value must correspond to the 
  name of a class in `mo-scaler`'s `autoscalers.py` module.
  
* `min_workers`: tells `mo-scaler` not to scale down fewer than this many workers.

* `autoscale_pause_interval`: when a scale up event occurs `mo-scaler` will refuse to scale up
  again for this many seconds to allow previously started workers to come online and start accepting
  workload.
  

After updating any of these settings you will need to rerun the recipe, either via the AWS console
or `mh-opsworks`:

`./bin/rake stack:commands:execute_recipes_on_layers layers="Ganglia" recipes="mh-opsworks-recipes::install-moscaler"`