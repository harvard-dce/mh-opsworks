**NOTE**: This is an alternate implementation of scaling unrelated to what's
described in [README.horizontal-scaling.md](README.horizontal-scaling.md). It uses cloudwatch metrics
only and does not account for things like workers being idle, their 
billed uptime, etc. It should be considered deprecated.

### Experimental Horizontal worker scaling

EXPERIMENTAL: Basic automatic horizontal worker scaling can be accomplished
through a combination of opsworks built-ins and custom metrics and alarms.

This is different than the `ec2_manager.py` horizontal scaling used by default
in that it uses opsworks built-in features to manage automatic instance
scaling. You should probably just use that by default.

You can disable this by editing your cluster config and setting "enable" to
`false` in the scaling section of the workers layer.

The `mh-opsworks-recipes::install-job-queued-metrics` recipe creates a
"MatterhornJobsQueued" metric bound to your Ganglia monitoring instance. You
need to add this recipe to the "setup" lifecycle event on the monitoring
instance. This metric is then used in the
`<your_cluster_name>_jobs_queued_high` alarm. When this alarm fires, the
workers are scaled up according to the parameters set in your cluster config.

Workers are scaled down less aggressively when the workers-wide CPU drops below
20%.  You will probably need to tweak these levels for your workload.

You can modify scaling behavior by editing the `scaling` section of the worker
layer's `instances` configuration. Options (except for `alarm_suffix`) are
passed directly through to the ruby SDK.

Example config, in the "workers" layer:


```
    "instances": {
      "number_of_instances": 4,

      .... more stuff

      "scaling": {
        "enable": true,
        "number_of_scaling_instances": "8",
        "up": {
          "instance_count": 2,
          "thresholds_wait_time": 1,
          "ignore_metrics_time": 2,
          "cpu_threshold": -1,
          "memory_threshold": -1,
          "load_threshold": -1,
          "alarm_suffix": "_jobs_queued_high"
        },
        "down": {
          "instance_count": 1,
          "thresholds_wait_time": 10,
          "ignore_metrics_time": 20,
          "cpu_threshold": 20.0,
          "memory_threshold": -1,
          "load_threshold": -1
        }
      }
    }
```

You can change the number of queued jobs that trigger the alarm in your cluster
config's `custom_json`:

```
{
  "stack": {
    "chef": {
      "custom_json": {
        "scale_up_when_queued_jobs_gt": 4
      },
    }
  }
}
```

After modifying this setting, you'll need to execute the
`mh-opsworks-recipes::install-job-queued-metrics` recipe against your Ganglia
monitoring instance.

