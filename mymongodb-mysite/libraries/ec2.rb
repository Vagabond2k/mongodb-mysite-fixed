#
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# TODO: once sync_libraries properly handles sub-directories, move this file to aws/libraries/opscode/aws/ec2.rb

require 'open-uri'

module Opscode
  module Aws
    module Ec2
      def find_snapshot_id(volume_id="", find_most_recent=false)
        snapshot_id = nil
        snapshots = if find_most_recent
          ec2.describe_snapshots.sort { |a,b| a[:aws_started_at] <=> b[:aws_started_at] }
        else
          ec2.describe_snapshots.sort { |a,b| b[:aws_started_at] <=> a[:aws_started_at] }
        end
        snapshots.each do |snapshot|
          if snapshot[:aws_volume_id] == volume_id
            snapshot_id = snapshot[:aws_id]
          end
        end
        raise "Cannot find snapshot id!" unless snapshot_id
        Chef::Log.debug("Snapshot ID is #{snapshot_id}")
        snapshot_id
      end

      def ec2
        @@ec2 ||= create_aws_interface(RightAws::Ec2)
      end

      def instance_id
        @@instance_id ||= query_instance_id
      end

      def instance_availability_zone
        @@instance_availability_zone ||= query_instance_availability_zone
      end

      private

      def create_aws_interface(aws_interface)
        begin
          require 'right_aws'
        rescue LoadError
          Chef::Log.error("Missing gem 'right_aws'. Use the default aws recipe to install it first.")
        end

        region = instance_availability_zone
        region = region[0, region.length-1]

        if new_resource.aws_access_key and new_resource.aws_secret_access_key
          aws_interface.new(new_resource.aws_access_key, new_resource.aws_secret_access_key, {:logger => Chef::Log, :region => region})
        else
          creds = query_role_credentials
          aws_interface.new(creds['AccessKeyId'], creds['SecretAccessKey'], {:logger => Chef::Log, :region => region, :token => creds['Token']})
        end
      end

      def query_role
        r = open("http://169.254.169.254/latest/meta-data/iam/security-credentials/").readlines.first
        r
      end

      def query_role_credentials(role = query_role)
        fail "Instance has no IAM role." if role.to_s.empty?
        creds = open("http://169.254.169.254/latest/meta-data/iam/security-credentials/#{role}"){|f| JSON.parse(f.string)}
        Chef::Log.debug("Retrieved instance credentials for IAM role #{role}")
        creds
      end

      def query_instance_id
        instance_id = open('http://169.254.169.254/latest/meta-data/instance-id'){|f| f.gets}
        raise "Cannot find instance id!" unless instance_id
        Chef::Log.debug("Instance ID is #{instance_id}")
        instance_id
      end

      def query_instance_availability_zone
        availability_zone = open('http://169.254.169.254/latest/meta-data/placement/availability-zone/'){|f| f.gets}
        raise "Cannot find availability zone!" unless availability_zone
        Chef::Log.debug("Instance's availability zone is #{availability_zone}")
        availability_zone
      end

    end
  end
end

