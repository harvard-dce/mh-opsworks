# CHANGELOG

* set default cluster cookbook revision to "oc-opsworks-5.x-recipes" (for now)

* MI-100: add vpc filter to security group finder api call (cherry-picked from main line)

* MI-98: remove EFS storage support

* MI-95: use multiple private subnets/AZs so worker spin-up isn't vulnerable to AZ capacity issues

* Incorporate utility layer/node creation into `cluster:new`
