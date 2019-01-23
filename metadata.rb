name             'persistent_lvm'
maintainer       'Kabam Games Inc.'
maintainer_email 'areznikov@kabaminc.com'
license          'Apache 2.0'
description      'Configures available persistent devices on a cloud server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'ubuntu'
supports 'centos'
supports 'debian'

depends 'lvm'

recipe "persistent_lvm::default", "Sets up persistent devices on a cloud server"

attribute "persistent_lvm/filesystem",
  :display_name => "persistent LVM Filesystem",
  :description =>
    "The filesystem to be used on the persistent volume." +
    " Defaults are based on OS and determined in attributes/defaults.rb.",
  :recipes => ["persistent_lvm::default"],
  :required => "recommended"

attribute "persistent_lvm/mount_point",
  :display_name => "persistent LVM Mount Point",
  :description => "The mount point for the persistent volume",
  :default => "/mnt/persistent",
  :recipes => ["persistent_lvm::default"],
  :required => "recommended"

attribute "persistent_lvm/mount_point_properties",
  :display_name => "persistent LVM Mount Properties",
  :description => "The options used when mounting the persistent volume",
  :type => "hash",
  :default => {:options => ["defaults", "noauto"], :pass => 0},
  :recipes => ["persistent_lvm::default"],
  :required => "optional"

attribute "persistent_lvm/volume_group_name",
  :display_name => "persistent LVM Volume Group Name",
  :description => "The volume group name for the persistent LVM",
  :default => "vg-data",
  :recipes => ["persistent_lvm::default"],
  :required => "optional"

attribute "persistent_lvm/logical_volume_size",
  :display_name => "persistent LVM Logical Volume Size",
  :description => "The size to be used for the persistent LVM",
  :default => "100%VG",
  :recipes => ["persistent_lvm::default"],
  :required => "optional"

attribute "persistent_lvm/logical_volume_name",
  :display_name => "persistent LVM Logical Volume Name",
  :description => "The name of the logical volume for persistent LVM",
  :default => "persistent0",
  :recipes => ["persistent_lvm::default"],
  :required => "optional"

attribute "persistent_lvm/stripe_size",
  :display_name => "persistent LVM Stripe Size",
  :description => "The stripe size to be used for the persistent logical volume",
  :default => "512",
  :recipes => ["persistent_lvm::default"],
  :required => "optional"
