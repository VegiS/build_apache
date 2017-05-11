#
# Cookbook:: build_cookbook
# Recipe:: lint
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

## First item of business, verify the config we use to build.
## Unit lint and syntax all launch about the same time, so they should also error out if the config is bad.
## This is mostly useful because the lint phase can be run independently via kitchen, for example.
ruby_block 'Test the configuration loads and has the required items' do
  block do
    conf_file = "#{workflow_workspace_repo}/#{node['apache_build']['config_file']}"
    parsed_conf = JSON.parse(File.read(conf_file)) # Read and parse the config file
    required_config_items = %w(apache_version apr_version apr_utils_version required_build_packages configure_options apache_source apr_source apr_utils_source build_number) # These items should not be nil
    required_config_items.each do |config_item|
      raise "The required config item #{config_item} is not set." if parsed_conf[config_item].nil?
    end
    with_server_config do
      cur_env = ::DeliveryTruck::Helpers::Provision.fetch_or_create_environment('delivered')
      unless cur_env.default_attributes['custom-apache'].nil?
        raise 'Build number needs an update' if cur_env.default_attributes['custom-apache']['build_number'] == parsed_conf['build_number']
      end
    end
  end
end
