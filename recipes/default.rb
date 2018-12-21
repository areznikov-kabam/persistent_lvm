#
# Cookbook Name:: persistent_lvm
# Recipe:: default
#
# Copyright (C) 2013 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Include the lvm::default recipe which sets up the resources/providers for lvm
#
include_recipe "lvm"

if !node.attribute?('cloud') || !node['cloud'].attribute?('provider') || !node.attribute?(node['cloud']['provider'])
  log "Not running on a known cloud, not setting up persistent LVM"
else
  # Obtain the current cloud
  cloud = node['cloud']['provider']

  # Obtain the available persistent devices. See "libraries/helper.rb" for the definition of
  # "get_persistent_devices" method.
  #
  persistent_devices = persistentLvm::Helper.get_persistent_devices(cloud, node)

  if persistent_devices.empty?
    log "No persistent disks found. Skipping setup."
  else
    log "persistent disks found for cloud '#{cloud}': #{persistent_devices.inspect}"

    # Create the volume group and logical volume. If more than one persistent disk is found,
    # they are created with LVM stripes with the stripe size set in the attributes.
    #
    lvm_volume_group node['persistent_lvm']['volume_group_name'] do
      physical_volumes persistent_devices

      logical_volume node['persistent_lvm']['logical_volume_name'] do
        size node['persistent_lvm']['logical_volume_size']
        filesystem node['persistent_lvm']['filesystem']
        mount_point node['persistent_lvm']['mount_point_properties'].merge(
          location: node['persistent_lvm']['mount_point']
        )
        if persistent_devices.size > 1
          stripes persistent_devices.size
          stripe_size node['persistent_lvm']['stripe_size'].to_i
        end
      end
    end
  end
end
