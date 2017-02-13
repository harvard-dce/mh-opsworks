# Enabling the capture agent manager app

The capture-agent-manager app is meant to be deployed in the utilities layer of
a mh cluster.

The capture-agent-manager app is a flask-gunicorn web app to keep capture agent
inventory, and provide an api/ui for configuring capture agents, as well as
switching from primary to secondary live stream..

* Modify your cluster config to include the following layer config:

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
            "oc-opsworks-recipes::set-timezone",
            "oc-opsworks-recipes::fix-raid-mapping",
            "oc-opsworks-recipes::set-bash-as-default-shell",
            "oc-opsworks-recipes::install-utils",
            "oc-opsworks-recipes::install-crowdstrike",
            "oc-opsworks-recipes::enable-postfix-smarthost",
            "oc-opsworks-recipes::install-custom-metrics",
            "oc-opsworks-recipes::create-alerts-from-opsworks-metrics",
            "oc-opsworks-recipes::enable-enhanced-networking",
            "oc-opsworks-recipes::install-cwlogs",
            "oc-opsworks-recipes::clean-up-package-cache",
            "oc-opsworks-recipes::create-capture-agent-manager-user",
            "oc-opsworks-recipes::create-capture-agent-manager-directories",
            "oc-opsworks-recipes::install-capture-agent-manager-packages",
            "oc-opsworks-recipes::install-capture-agent-manager",
            "oc-opsworks-recipes::configure-capture-agent-manager-gunicorn",
            "oc-opsworks-recipes::configure-capture-agent-manager-nginx-proxy",
            "oc-opsworks-recipes::configure-capture-agent-manager-supervisor"
          ],
          "shutdown": [
            "oc-opsworks-recipes::remove-alarms"
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

* Update your "custom_json" block to provide the following info to `cadash`:

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

  These attributes have defaults:

  1.  capture_agent_manager_app_name: "cadash"

      name of the flask-gunicorn app

  2.  capture_agent_manager_usr_name: "capture_agent_manager"

      user that app runs as, and is created during setup

  3.  capture_agent_manager_secret_key: "super_secret_key"

      you need to set this to a less obvious value. One way to generate a key is via
      python:

          $> python
          Python 2.7.11 (default, Jan 22 2016, 08:29:18)
          [GCC 4.2.1 Compatible Apple LLVM 7.0.2 (clang-700.1.81)] on darwin
          Type "help", "copyright", "credits" or "license" for more information.
          >>> import os
          >>> os.urandom(24)
          'r\xe3\x83\x1ad\xe1\xbeI\x02\x86\xb9:J\xdfaah\xda\xb7\x97\x82\x96;G'
          >>>

  4.  capture_agent_manager_gunicorn_log_level: "debug"

      change this to "info", "warning", "error"... as needed

  5.  log_config: "/home/capture_agent_manager/sites/cadash/logging.yaml"

      where the app logging settings live. You might want to change the settings
      in a different file or edit the defaults. To change default you have to
      commit new settings in the app git repo (see capture_agent_manager_git_repo below)

  6.  ca_stats_user: "usr" and ca_stats_passwd: "pwd"

      user and passwd for the capture_agent_status_board page. Change with correct
      values. In the future, this board will be implemented as part of the
      capture_agent_manager app and will be deprecated.

  7.  ca_stats_json_url: "http://fake-ca-status.com/ca-status.json"

      the url for the json provided by the capture_agent_status_board page. Change
      with correct value.

  8.  epipear_user: "usr" and epipearl_passwd: "pwd"

      for now, the capture_agent_manager app assumes that all capture agents are
      epiphan-pearl and that all devices have the same user/password combination for
      api access. Change with correct values.

  9.  ldap_host: "ldap-hostname.some-domain.com"

      ldap hostname, for user authorization in the capture_agent_manager app. Change
      with correct value -- ask sysops for the production and development hostnames.

  10. ldap_base_search: "dc=some-domain,dc=com"

      change with correct value. Folks in sysops can help you with that.

  11. ldap_bind_dn: "cn=fake_usr,dc=some-domain,dc=com" and ldap_bind_passwd: "pwd"

      ldap user to consult with ldap for authorization in teh capture_agent_manager app.
      Again, sysops knows.

  12. capture_agent_manager_git_repo: "https://github.com/harvard-dce/cadash"

      repo for the capture_agent_manager app. Change only if you are using a fork or,
      maybe, some other capture_agent_manager app.

  13. capture_agent_manager_git_revision: "master"

      git branch or tag for the capture_agent_manager app that you want to deploy.

  14. capture_agent_manager_database_usr: "usr" and capture_agen_manager_pwd: "pwd"

      these are placeholders, not used currently in production.


* execute `./bin/rake admin:cluster:init` and `./bin/rake stack:instances:start`
  to initialize and start the new layer/instance.


## What you get

* an instance in the utility layer running the capture-agent-manager `cadash` app:
    * flask-gunicorn web app with dce-ldap authorization
    * redundancy live `redunlive` to toggle from primary to secondary
      live streams (when there is a problem with the primary live)




# Enabling Capture Agent Time Drift Monitoring

The utility node collect time from each capture agent and calculate the
difference (with its local system time, for now good enough) and post the
difference as a cloudwatch metric.

To do this add the recipe in the setup phase of the utility node:
```
    oc-opsworks-recipes::install-ca-timedrift-metric
```

And add the capture agent private ssh key to the custom json var
`capture_agent_manager`:

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
          "capture_agent_manager_database_pwd": "dbpwd",
          "ca_private_ssh_key": "----- BEGIN PRIVATE KEY -----\nPatatiPatata..."
        },
    }
```
