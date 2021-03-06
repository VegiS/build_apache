#
# Cookbook:: build_cookbook
# Recipe:: set_up_build
#
# Copyright:: 2017, Jp Robinson
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

# Steps to set up a build of the correct apache version
build_config = ab_load_config(node['apache_build']['config_file']) # Load and parse the config file

## Because the build runs as the build user (dbuild), to install the packages required to build, we must have passwordless sudo set up
## for the build user or the build nodes must have all the packages required for a build installed already.
## Either choice must be done outside of the actual build cookbook.
## It is, of course, recommended you use chef to manage any pre-reqs for your build nodes via a cookbook.
execute "sudo yum install -y #{build_config['required_build_packages']} >/dev/null"

src_dir = "#{workflow_workspace_repo}/httpd" # Root directory for the source to go into on the build node

# Check out source code from git
git src_dir do
  repository build_config['apache_source']
  revision build_config['apache_version']
end

git "#{src_dir}/srclib/apr" do
  repository build_config['apr_source']
  revision build_config['apr_version']
end
git "#{src_dir}/srclib/apr-util" do
  repository build_config['apr_utils_source']
  revision build_config['apr_utils_version']
end

bash 'Building autoconf script' do
  code "#{src_dir}/buildconf"
  cwd src_dir
end
