#
# Cookbook Name:: mariadb
# Recipe:: server
#
# Copyright 2014, blablacar.com
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

case node['mariadb']['install']['type']
when 'package'
  include_recipe "#{cookbook_name}::repository"

  case node['platform']
  when 'debian', 'ubuntu'
    include_recipe "#{cookbook_name}::_debian_server"
  when 'redhat', 'centos', 'fedora'
    include_recipe "#{cookbook_name}::_redhat_server"
  end
when 'from_source'
  # To be filled as soon as possible
end

include_recipe "#{cookbook_name}::config"

# restart the service if needed
# workaround idea from https://github.com/stissot
Chef::Resource::Service.send(:include, MariaDB::Helper)
service 'mysql' do
  action :restart
  only_if do
    mariadb_service_restart_required?(
      '127.0.0.1',
      node['mariadb']['mysqld']['port'],
      node['mariadb']['mysqld']['socket']
    )
  end
end

if node['mariadb']['allow_root_pass_change']
  # Used to change root password after first install
  # Still experimental
  if node['mariadb']['server_root_password'].empty?
    md5 = Digest::MD5.hexdigest('empty')
  else
    md5 = Digest::MD5.hexdigest(node['mariadb']['server_root_password'])
  end

  file '/etc/mysql_root_change' do
    content md5
    action :create
    notifies :run, 'execute[install-grants]', :immediately
  end
end

if  node['mariadb']['allow_root_pass_change'] ||
    node['mariadb']['forbid_remote_root']
  execute 'install-grants' do
    command '/bin/bash /etc/mariadb_grants \'' + \
            node['mariadb']['server_root_password'] + '\''
    only_if { File.exist?('/etc/mariadb_grants') }
    action :nothing
  end

  template '/etc/mariadb_grants' do
    source 'mariadb_grants.erb'
    owner 'root'
    group 'root'
    mode '0600'
    notifies :run, 'execute[install-grants]', :immediately
  end
end
