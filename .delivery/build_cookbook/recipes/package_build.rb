#
# Cookbook:: build_cookbook
# Recipe:: package_build
#
# Copyright:: 2017, Jp Robinson .
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


include_recipe 'build_cookbook::perform_build' # Make sure prereqs are done
with_server_config do # Chef server context, so we can get the databag.
  begin
    publish_info = data_bag_item('build_apache', 'publish_info')
  rescue
    Chef::Log.warn 'Unable to get data bag, not able to publish'
    publish_info = {}
  end

  # Steps to package up what is produced by the build
  build_config = ab_load_config(node['apache_build']['config_file']) # Load and parse the config file
  dev_null = '2>&1>/dev/null' if build_config['less_output']
  build_file = "custom-httpd-#{build_config['build_number']}.tar.gz"
  src_dir = "#{workflow_workspace_repo}/httpd" # Root source directory
  build_root = "#{workflow_workspace_repo}/build"
  # Clean the build dir just to make sure we are doing this cleanly
  bash 'Cleaning build directory' do
    code "rm -rf #{build_root}"
  end
  bash 'Running Make install' do
    code "make DESTDIR=#{build_root} install #{dev_null}"
    cwd src_dir
  end

  bash 'Packaging build' do
    code "tar cvzf #{workflow_workspace_repo}/#{build_file} * #{dev_null}"
    cwd build_root
  end

  ## Publish the tar file
  unless publish_info.empty?
    file "#{workflow_workspace_repo}/ssh_key" do
      content publish_info['key']
      mode '0700'
      sensitive true
    end

    sudo = 'sudo' if publish_info['sudo']
    bash 'Publishing tar file' do
      code <<-EOH
        scp -o StrictHostKeyChecking=no -i #{workflow_workspace_repo}/ssh_key #{workflow_workspace_repo}/#{build_file} #{publish_info['user']}@#{publish_info['host']}:~/
        ssh -o StrictHostKeyChecking=no -i #{workflow_workspace_repo}/ssh_key #{publish_info['user']}@#{publish_info['host']} "#{sudo} mv ~/#{build_file} #{publish_info['dir']}/; #{sudo} chown apache.apache #{publish_info['dir']}/#{build_file}"
        EOH
      action :run
    end
  end
end
