#
# Cookbook Name:: mymongo
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "mongodb::10gen_repo"
include_recipe "mongodb::default"
include_recipe "opscode::aws"
aws_ebs_volume "mysql_data_volume" do
  provider "aws_ebs_volume"
  volume_id "vol-524dee17"
  availability_zone "us-east-1"
  device "/dev/xvdi"
  action :attach
end
