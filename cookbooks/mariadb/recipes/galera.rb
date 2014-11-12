#
# Cookbook Name:: mariadb
# Recipe:: galera
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
  # include MariaDB repositories
  include_recipe "#{cookbook_name}::repository"

  case node['platform']
  when 'debian', 'ubuntu'
    include_recipe "#{cookbook_name}::_debian_galera"
  when 'redhat', 'centos', 'fedora'
    include_recipe "#{cookbook_name}::_redhat_galera"
  end
when 'from_source'
  # To be filled as soon as possible
end

if node['mariadb']['galera']['wsrep_sst_method'] == 'rsync'
  package 'rsync' do
    action :install
  end
else
  if node['mariadb']['galera']['wsrep_sst_method'] == 'xtrabackup'
    package 'percona-xtrabackup' do
      action :install
    end

    package 'socat' do
      action :install
    end
  end
end

include_recipe "#{cookbook_name}::config"

galera_cluster_nodes = []
if !node['mariadb'].attribute?('rspec') && Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
else
  galera_cluster_nodes = search(
    :node, \
    "mariadb_galera_cluster_name:#{node['mariadb']['galera']['cluster_name']}"
  )
end

first = true
gcomm = 'gcomm://'
galera_cluster_nodes.each do |lnode|
  next unless lnode.name != node.name
  gcomm += ',' unless first
  gcomm += lnode.name
  first = false
end

galera_options = {}

galera_options['wsrep_cluster_address'] = gcomm
galera_options['wsrep_cluster_name']    = \
  node['mariadb']['galera']['cluster_name']
galera_options['wsrep_sst_method']      = \
  node['mariadb']['galera']['wsrep_sst_method']
if node['mariadb']['galera'].attribute?('wsrep_sst_auth')
  galera_options['wsrep_sst_auth']        = \
    node['mariadb']['galera']['wsrep_sst_auth']
end
galera_options['wsrep_provider']        = \
  node['mariadb']['galera']['wsrep_provider']
galera_options['wsrep_slave_threads']   = node['cpu']['total'] * 4
node['mariadb']['galera']['options'].each do |key, value|
  galera_options[key] = value
end

mariadb_configuration 'galera' do
  section 'mysqld'
  option galera_options
  action :add
end

#
# Under debian system we have to change the debian-sys-maint default password.
# This password is the same for the overall cluster.
#
if platform?('debian', 'ubuntu')
  template '/etc/mysql/debian.cnf' do
    source 'debian.cnf.erb'
    owner 'root'
    group 'root'
    mode '0600'
  end

  execute 'correct-debian-grants' do
    command 'mysql -r -B -N -e "GRANT SELECT, INSERT, UPDATE, DELETE, ' + \
      'CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ' + \
      'ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, ' + \
      'LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, ' + \
      'CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, ' + \
      "CREATE USER, EVENT, TRIGGER ON *.* TO '" + \
      node['mariadb']['debian']['user'] + \
      "'@'" + node['mariadb']['debian']['host'] + "' IDENTIFIED BY '" + \
      node['mariadb']['debian']['password'] + "' WITH GRANT OPTION\""
    action :run
    only_if do
      cmd = Mixlib::ShellOut.new("/usr/bin/mysql --user=\"" + \
        node['mariadb']['debian']['user'] + \
        "\" --password=\"" + node['mariadb']['debian']['password'] + \
        "\" -r -B -N -e \"SELECT 1\"")
      cmd.run_command
      cmd.error?
    end
    ignore_failure true
  end
end
