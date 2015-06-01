# Configuring a cluster to connect to zadara storage

## mh-opsworks and `cluster_config.json` changes

The list below represents the `cluster_config.json` level changes necessary to
connect a cluster to zadara (or perhaps other) external storage.

1. Create your VPC via `./bin/rake vpc:init`
1. Now create your zadara storage volumes (see below). Come back and continue
   with the next step when that's done.
1. Remove the storage layer entirely in your `cluster_config.json`
1. Move the `mh-opsworks-recipes::nfs-client` recipe to the `setup` lifecycle
   event for the Admin, Engage, and Workers layers after the
   "mh-opsworks-recipes::create-matterhorn-user" recipe. Technically this is
   optional, but it's highly recommended as there's no need to restart autofs as
   nodes come online: the storage server is already ready for connections.
1. Edit your cluster config use the external storage you created. It should
   look something like:

        ...
        "stack": {
          "chef": {
            "custom_json": {
              "storage": {
                "export_root": "<the exported mount you created above>",
                "type": "external",
                "nfs_server_host": "<the nfs server host you created above>"
              }
            }
          }
        }
        ...

1. Provision the rest of your cluster: `./bin/rake admin:cluster:init` You
   should not see a "Storage" layer.
1. Start your instances via `./bin/rake stack:instances:start`

You should now be using zadara provisioned storage. Be sure to implement
monitoring and alerts for your external storage.

## Zadara volume provisioning

Zadara VPSA creation is discussed in more detail
[here](https://support.zadarastorage.com/entries/62983384-Getting-started-with-AWS-and-Zadara-).

1. Create the VPSA in the main zadara web console with a controller and some drives
1. Send an email to zadara with the AWS account name and account number, under
   the "my account" menu option in the aws web console.
1. While you're waiting for the VPSA, create a virtual gateway.
1. Accept the virtual interface zadara created under "direct connect" in the
   aws console and link to the virtual gateway you created above.
1. Attach the virtual gateway to the VPC you created for your cluster.
1. Allow the virtual gateway provided routes to propagate in all the route
   tables of your VPC - both private and public subnets.
1. Log in to the remote VPSA through an SSH tunnel over your VPC, something
   like `ssh -L 8080:<zadara hostname>:80 <external IP in your cluster>`. The
   VPSA gui should now be available on `http://localhost:8080`.  The easiest way
   to do this might be to add a throwaway custom layer that contains a single
   instance with a public IP and the default chef recipes. The instance in this
   layer allows you to access the VPSA GUI from the correct VPC. After you've
   configured the volume, you can remove the layer and the throwaway instance.
1. Create a RAID group from your drives that'll be used to populate a pool.
1. Create NAS users with username/UID mappings, probably for only for
   matterhorn, uid 2122.
1. Create NAS groups with group name / GID mappings, probably only for
   matterhorn, gid 2122.
1. Carve a NAS volume from the pool you previously created. The export name is
   set by the volume, as an NFS server can have multiple exports. Use a name
   that makes sense for your cluster.
1. Create a server with a CIDR block that matches your VPC and/or relevant
   subnets
1. Attach the volume you created above to this server.
1. You should now have the information you need to update your
   `cluster_config.json` for external storage.
