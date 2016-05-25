# enabling the capture agent manager app

the capture-agent-manager app is meant to be deployed in the utilities layer of
a mh cluster.

the capture-agent-manager app is a flask-gunicorn web app to keep capture agent
inventory, and provide an api/ui for configuring capture agents, as well as
switching from primary to secondary live stream..

* modify your cluster config to include the following layer config:

```
      {
        "name": "Utility",
        "shortname": "utility",
        "type": "custom",
        "enable_auto_healing": true,
        "install_updates_on_boot": true,
        "use_ebs_optimized_instances": true,
        "auto_assign_elastic_ips": true,
        "auto_assign_public_ips": true,
        "custom_recipes": {
          "setup": [
            "mh-opsworks-recipes::set-timezone",
            "mh-opsworks-recipes::fix-raid-mapping",
            "mh-opsworks-recipes::set-bash-as-default-shell",
            "mh-opsworks-recipes::install-utils",
            "mh-opsworks-recipes::enable-postfix-smarthost",
            "mh-opsworks-recipes::install-custom-metrics",
            "mh-opsworks-recipes::create-alerts-from-opsworks-metrics",
            "mh-opsworks-recipes::enable-enhanced-networking",
            "mh-opsworks-recipes::clean-up-package-cache",
            "mh-opsworks-recipes::create-capture-agent-manager-user",
            "mh-opsworks-recipes::create-capture-agent-manager-directories",
            "mh-opsworks-recipes::install-capture-agent-manager-packages",
            "mh-opsworks-recipes::install-capture-agent-manager",
            "mh-opsworks-recipes::configure-capture-agent-manager-gunicorn",
            "mh-opsworks-recipes::configure-capture-agent-manager-nginx-proxy",
            "mh-opsworks-recipes::configure-capture-agent-manager-supervisor"
          ],
          "shutdown": [
            "mh-opsworks-recipes::remove-alarms"
          ]
        },
        "volume_configurations": [

        ],
        "instances": {
          "number_of_instances": 1,
          "instance_type": "t2.medium",
          "root_device_type": "ebs"
        }
      },
```

* update your "custom_json" block to provide the following info to `cadash`:

```
    {
        "capture_agent_manager": {
          "capture_agent_manager_app_name": "cadash",
          "capture_agent_manager_usr_name": "capture_agent_manager",
          "capture_agent_manager_gunicorn_log_level": "debug",
          "ca_stats_user": "usr",
          "ca_stats_passwd": "pwd",
          "ca_stats_json_url": "http://ca-status.org/ca-status.json",
          "epipearl_user": "usr",
          "epipearl_passwd": "pwd",
          "ldap_host": "ldap.host.edu",
          "ldap_base_search": "dc=dce,dc=harvard,dc=edu",
          "ldap_bind_dn": "cn=usr,dc=ldap,dc=harvard,dc=edu",
          "ldap_bind_passwd": "pwd",
          "capture_agent_manager_secret_key": "super_secret_key",
          "log_config": "/home/capture_agent_manager_name/sites/cadash/logging.yaml",
          "capture_agent_manager_git_repo": "https://github.com/harvard-dce/cadash",
          "capture_agent_manager_git_revision": "master",
          "capture_agent_manager_database_usr": "dbusr",
          "capture_agent_manager_database_pwd": "dbpwd"
        },
    }
```

* execute `./bin/rake admin:cluster:init` and `./bin/rake stack:instances:start`
  to initialize and start the new layer/instance.

## What you get

* an instance in the utility layer running the capture-agent-manager `cadash` app:
    * flask-gunicorn web app with dce-ldap authorization
    * redundancy live `redunlive` to toggle from primary to secondary
      live streams (when there is a problem with the primary live)

