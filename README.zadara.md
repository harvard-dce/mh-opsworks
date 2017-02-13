# Configuring a cluster to connect to zadara storage

## oc-opsworks and cluster configuration changes

The list below represents the cluster configuration level changes necessary to
connect a cluster to zadara (or perhaps other) external storage.

1. Run './bin/rake cluster:new' and choose one of the zadara variants. If you
   don't know the path to volume you're exporting or the IP to the zadara NFS
   server, that's fine. Our standard path is `/var/matterhorn`.
   Enter anything that looks like a path or IP address and
   you can use `./bin/rake cluster:edit` to fix it later.
1. Create your VPC via `./bin/rake vpc:init`
1. Now create your zadara storage volumes (see below). Come back and continue
   with the next step when that's done.
1. Provision the rest of your cluster: `./bin/rake admin:cluster:init` You
   should not see a "Storage" layer.
1. Start your instances via `./bin/rake stack:instances:start`

You should now be using zadara provisioned storage. Be sure to implement
monitoring and alerts for your external storage.

## Zadara volume provisioning

Zadara VPSA creation is discussed in more detail
[here](https://support.zadarastorage.com/entries/62983384-Getting-started-with-AWS-and-Zadara-).

### First time:

1. Create the VPSA in the main zadara web console with a controller and some drives
1. Send an email to zadara with the AWS account name and account number, under
   the "my account" menu option in the aws web console.
1. While you're waiting for the VPSA, create a virtual private gateway or find one that's not already being used.
1. Accept the virtual interface zadara created under "direct connect" in the
   aws console and link to the virtual private gateway you created above.

### Every VPC (and therefore cluster):

1. Attach the virtual private gateway to the VPC you created for your cluster.
1. Allow the virtual private gateway provided routes to propagate in all the
   route tables of your VPC - both private and public subnets. **Important**: you must update the propogate setting for **all** the route tables. This is under
   "Route Tables", and then the "Route Propagation" tab. It probably makes sense
   to filter by your VPC to make things easier.  There's a UI bug that makes it
   look like routes are propagating but they may not be - switch to each route
   and refresh the page to ensure you've actually made a change and that it's taken.
1. Log in to the remote VPSA through an SSH tunnel over your VPC, something
   like `ssh -L 8080:<zadara hostname>:80 <external IP in your cluster>`. The
   VPSA gui should now be available on `http://localhost:8080`.  The easiest way
   to do this is to add a throwaway custom layer that contains a single instance
   with a public IP and the default chef recipes. Start up this instance and it
   will allow you to access the VPSA GUI from the correct VPC. After you've
   successfully connected your cluster, you can remove the layer and the
   throwaway instance.
1. Create a RAID group from your drives that'll be used to populate a pool.
1. Carve a NAS volume from the pool you previously created. The export name is
   set by the volume, as an NFS server can have multiple exports. Use a name
   that makes sense for your cluster.
1. Create a server with a CIDR block that matches your VPC and/or relevant
   subnets. Ensure that "root squash" is enabled.
1. Attach the volume you created above to this server.
1. You should now have the information you need to update your
   cluster configuration for external storage. Return the previous section.

## Removing a zadara-backed cluster

Removing a zadara cluster is almost the same process as removing a normal
cluster - `./bin/rake admin:cluster:delete`.

The VPC will probably not delete cleanly - you should:

1. manually detach the virtual private gateway,
1. manually delete the VPC,
1. remove the cloudformation stack, and then
1. run `./bin/rak admin:cluster:delete` again.

You might want to remove and/or reformat the volume you've exported to free up
space.

# Setting up s3 object storage backups

Zadara's docs
[here](https://support.zadarastorage.com/entries/69891364-Setup-Backup-To-S3-B2S3-Through-a-Proxy-In-Your-AWS-VPC).

One thing not clear from the docs - every snapshot policy that you want to back
up needs to go into its own bucket. This also means you will probably
duplicate your entire volume into multiple buckets.

If you want to object store more than one snapshot type, just create multiple
buckets and add them to the list in the IAM user's inline policy (below).

* Create or use a zadara-connected cluster.
* Create or use an opsworks instance with a public IP as your zadara squid
  proxy.
* Add the `oc-opsworks-recipes::create-squid-proxy-for-storage-cluster` recipe
  to the layer's `setup` lifecycle. Run it to create the squid3 proxy.
* Add a rule to the layer's security group (e.g. Utility) that opens port 3128
  to the IP of your VPSA
* Create an s3 bucket to hold your snapshots. Default policies and access
  controls should be fine.
* Create an IAM user with access credentials and a inline policy that looks
  like:

        {
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": "s3:ListAllMyBuckets",
                    "Resource": "arn:aws:s3:::*"
                },
                {
                    "Effect": "Allow",
                    "Action": "s3:*",
                    "Resource": [
                        "arn:aws:s3:::<your s3 snapshot bucket name>",
                        "arn:aws:s3:::<your s3 snapshot bucket name>/*"
                    ]
                }
            ]
        }

* Log in to your VPSA.
* Add a "Connection" under "Remote Storage" -> "Remote Object Storage".  Set
  the private IP of your squid proxy instance and port 3128 as your proxy,
  while connecting it to the IAM credentials and bucket you've just created. The
  connection will be tested when you add it.
* Hit "create" under "Data Protection" -> "Backup to Object Storage". Glue your
  volume, snapshot policy and remote connection together and save it.
* You now have s3 backed snapshots.

