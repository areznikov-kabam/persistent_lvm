#
# Cookbook Name:: persistent_lvm
# Library:: helper
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

module persistentLvm
  module Helper
    # Identifies the persistent devices available on a cloud server based on cloud-specific Ohai data and returns
    # them as an array. This method also does the mapping required for Xen hypervisors (/dev/sdX -> /dev/xvdX).
    #
    # @param cloud [String] the name of cloud
    # @param node [Chef::Node] the Chef node
    #
    # @return [Array<String>] list of persistent available persistent devices.
    #
    def self.get_persistent_devices(cloud, node)
      persistent_devices = []
      # Detects the persistent disks available on the instance.
      #
      # If the cloud plugin supports block device mapping on the node, obtain the
      # information from the node for setting up block device
      #
      case cloud
      when 'gce'
        # According to the GCE documentation, the instances have links for persistent disks as
        # /dev/disk/by-id/google-persistent-disk-*. Refer to
        # https://developers.google.com/compute/docs/disks#scratchdisks for more information.
        #
        #we skip the very first device as it's root PD-SSD device 
        persistent_devices = node[cloud]['attached_disks']['disks'].map do |disk|
          if (disk['type'] == "PERSISTENT" or disk['type'] == "PERSISTENT-SSD") && disk['deviceName']!= "persistent-disk-0"
            "/dev/disk/by-id/scsi-0Google_PersistentDisk_#{disk["deviceName"]}"
          end
        end
        #persistent_devices might be empty still. I guess it's caused by different chef versions
        #second try to discover attached disks
        if persistent_devices.empty?
          persistent_devices = node[cloud]['instance']['attributes']['disks'].map do |disk|
            if (disk['type'] == "PERSISTENT" or disk['type'] == "PERSISTENT-SSD") && disk['deviceName']!= "persistent-disk-0" && disk['deviceName']!= "boot-volume"
              "/dev/disk/by-id/scsi-0Google_PersistentDisk_#{disk["deviceName"]}"
            end
          end
        end
        # Removes nil elements from the persistent_devices array if any.
        persistent_devices.compact!
        Chef::Log.info "Persistent disks found for cloud '#{cloud}': #{persistent_devices.inspect}"
      else
        # assume AWS and taking generic approach
        # Read devices that are currently in use from the last column in /proc/partitions
        partitions = IO.readlines('/proc/partitions').drop(2).map { |line| line.chomp.split.last }
        # Eliminate all LVM partitions
        partitions = partitions.reject { |partition| partition =~ /^dm-\d/ }
        # Get all the devices in the form of sda, xvda, hda, etc.
        persistent_devices = partitions.select { |partition| partition =~ /[a-z]$/ }.sort.map { |device| "/dev/#{device}" }
        # If no devices found in those forms, check for devices in the form of sda1, xvda1, hda1, etc.
        if persistent_devices.empty?
          persistent_devices = partitions.select { |partition| partition =~ /[0-9]$/ }.sort.map { |device| "/dev/#{device}" }
        end
          
        # Now it's time to remove devices detected as ephemeral from ohai
        ephemeral_devices = []
        # Detects the ephemeral disks available on the instance.
        #
        if node[cloud].keys.any? { |key| key.match(/^block_device_mapping_ephemeral\d+$/) }
          ephemeral_devices = node[cloud].map do |key, device|
            if key =~ /^block_device_mapping_ephemeral\d+$/
              device =~ %r{\/dev\/} ? device : "/dev/#{device}"
            end
          end
        end
        # Removes nil elements from the ephemeral_devices array if any.
        ephemeral_devices.compact!
        #
        #Final step: now we need to remove all the devices reported as ephemeral by ohai to be on the safe side
        persistent_devices.reject!(|device| ephemeral_devices.include? device)
        Chef::Log.info "Persistent disks found for nocloud detected': #{persistent_devices.inspect}"
        end
      end
      persistent_devices
    end

    # Fixes the device mapping on Xen hypervisors. When using Xen hypervisors, the devices are mapped from /dev/sdX to
    # /dev/xvdX. This method will identify if mapping is required (by checking the existence of unmapped device) and
    # map the devices accordingly.
    #
    # @param devices [Array<String>] list of devices to fix the mapping
    # @param node_block_devices [Array<String>] list of block devices currently attached to the server
    #
    # @return [Array<String>] list of devices with fixed mapping
    #
    def self.fix_device_mapping(devices, node_block_devices)
      devices.map! do |device|
        if node_block_devices.include?(device.match(/\/dev\/(.+)$/)[1])
          device
        else
          fixed_device = device.sub("/sd", "/xvd")
          if node_block_devices.include?(fixed_device.match(/\/dev\/(.+)$/)[1])
            fixed_device
          else
            Chef::Log.warn "could not find persistent device: #{device}"
            nil
          end
        end
      end
      devices.compact
    end
  end
end
