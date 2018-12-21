#/usr/bin/env bats

# On CentOS 5.9, most of the commands used here are not in PATH. So add them
# here.
export PATH=$PATH:/sbin:/usr/sbin

@test "google persistent disk by-id symbolic links exist" {
  test -L /dev/disk/by-id/google-persistent-disk-0
  test -L /dev/disk/by-id/google-persistent-disk-1
}

@test "physical volumes are created for persistent devices" {
  pvs | grep /dev/loop0
  pvs | grep /dev/loop1
}

@test "volume group is created for persistent devices" {
  vgs | grep vg-data
}

@test "logical volume is created for persistent devices on the correct volume group" {
  lvs | grep vg-data | grep persistent0
}

# The `lvs --segments --separator :` command outputs in the following format
# 'LV:VG:Attr:#Str:Type:SSize' where '#Str' is the number of stripes and 'Type' is 'striped'
# if the LVM is striped and 'linear' otherwise.
#
@test "logical volumes are striped" {
  lvs --segments --separator : | grep -P "persistent0:vg-data.*:2:striped"
}

@test "persistent logical volume is mounted to /mnt/persistent" {
  if type -P lsb_release; then
    is_rhel=`lsb_release -sir | grep -Pqiz "^(centos|redHatEnterpriseServer)\s6\." && echo "true" || echo "false"`
  else
    # On RHEL: Red Hat Enterprise Linux Server release 7.1 (Maipo)
    # On CentOS: CentOS Linux release 7.0.1406 (Core)
    is_rhel=`grep -Pqiz "^(centos|red hat enterprise) linux.+ 7\." /etc/redhat-release && echo "true" || echo "false"`
  fi

  if [[ $is_rhel == "true" ]]; then
    filesystem='xfs'
  else
    filesystem='ext4'
  fi
  mountpoint /mnt/persistent
  mount | egrep "^/dev/mapper/vg--data-persistent0 on /mnt/persistent type $filesystem"
  egrep "/dev/mapper/vg--data-persistent0\s+/mnt/persistent\s+$filesystem\s+defaults,noauto\s+0\s+0" /etc/fstab
}
