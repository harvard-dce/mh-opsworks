# Enabling DCE-specific authentication

* Set up two route53 managed records under our *.harvard.edu domain that point to:
  * Your admin EIP and
  * Your engage server EIP.
* Ask to have your engage server EIP whitelisted with the authentication server
  by submitting a service desk ticket. You will need ensure this whitelisting
  happens before auth will work correctly.
* Modify your cluster config to include the following:

        "chef": {
          "custom_json": {
            "public_engage_hostname": "the engage route53 domain you created",
            "public_admin_hostname": "the admin route53 domain you created",
            "auth_activated": "true",
            "auth_host": "the hostname of the auth server",
            "auth_redirect_location": "https://login-page-on-auth_host-above",
            ... everything else...
          }
        }

* Redeploy your cluster and restart matterhorn. Videos uploaded previously may
  not work correctly because the full URLs are rendered into the database and
  media packages.
