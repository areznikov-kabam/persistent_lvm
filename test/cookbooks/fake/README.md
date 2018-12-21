# fake cookbook

# Requirements

Requires the `persistent_lvm` cookbook.

# Usage

This cookbook is only used to test the `persistent_lvm` cookbook.

# Attributes

`node['fake']['devices']` - The persistent devices to be used for testing

# Recipes

## default

This recipe prepares the server with some loop devices as persistent disks.

## gce

This recipe prepares the server to mimic the behavior of GCE cloud by setting up the links to persistent devices.

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
