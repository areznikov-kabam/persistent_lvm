# ebs_lvm cookbook

Based on https://github.com/rightscale-cookbooks/ephemeral_lvm. Just rewritten to discover EBS volumes instead and set them up.
This approach is quite straighforward and requires minimum effort. EBS/PD-SSD volume setup is outside of the scope of the cookbook.
It should be taken care by some other cookbook/tool, in our case it will be Terraform.

This cookbook will identify the ebs devices available on the instance based on Ohai data. If no ebs devices
are found, it will gracefully exit with a log message. If ebs devices are found, they will be setup to
use LVM and a logical volume will be created, formatted, and mounted. If multiple ebs devices are found
(e.g. m1.large on EC2 has 2 persistent devices with 420 GB each), they will be striped to create the LVM.


# Requirements

* Chef 11 or higher
* A cloud that supports persistent devices. Currently supported clouds: EC2 and Google.
* Cookbook requirements
  * [lvm](http://community.opscode.com/cookbooks/lvm)

# Usage

Place the `persistent_lvm::default` in the runlist and the persistent devices will be setup.

# Attributes

* `node['persistent_lvm']['filesystem']` - the filesystem to be used on the persistent volume. Default: `'ext4'`
* `node['persistent_lvm']['mount_point']` - the mount point for the persistent volume. Default: `'/mnt/persistent'`
* `node['persistent_lvm']['mount_point_properties']` - the options used when mounting the persistent volume. Default: `{options: ['defaults', 'noauto'], pass: 0}`
* `node['persistent_lvm']['volume_group_name']` - the volume group name for the persistent LVM. Default: `'vg-data'`
* `node['persistent_lvm']['logical_volume_size']` - the size to be used for the persistent LVM. Default: `'100%VG'` - This will use all available space in the volume group.
* `node['persistent_lvm']['logical_volume_name']` - the name of the logical volume for persistent LVM. Default: `'persistent0'`
* `node['persistent_lvm']['stripe_size']` - the stripe size to be used for the persistent logical volume. Default: `512`

# Recipes

## default

This recipe sets up available persistent devices to be an LVM device, formats it, and mounts it.

# Author

Author:: Kabam Games Inc. (<areznikov@rightscale.com>)
