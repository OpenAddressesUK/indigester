package 'git'
package 'mariadb-server'
package 'python-mysqldb'

oa_user = 'openaddresses'

user oa_user do
  home '/home/%s' % oa_user
  shell '/bin/bash'
  supports manage_home: true
  action :create
end

deploy_root = '/home/%s/etl' % oa_user

directory deploy_root do
  owner oa_user
  action :create
end

%w{
  common-ETL
  companies-house-ETL
}.each do |etl|
  git '%s/%s' % [ deploy_root, etl ] do
    user oa_user
    repository 'https://github.com/OpenAddressesUK/%s' % etl
    action :sync
  end
end

execute 'create database' do
  command 'mysql -e "create database if not exists commonetldb"'
end

execute 'run sql' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'mysql commonetldb < oa_alpha_etl.sql'
end

execute 'grab OS Locator data' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'python OS_Locator_download.py'
end

execute 'grab ONSPD data' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'python ONSPD_download.py'
end

template '/home/openaddresses/etl/common-ETL/oa_alpha_etl.cnf' do
  source 'oa_alpha_etl.cnf.erb'
  variables({
    api_key: node['ernest_api_key']
    })
  action :create
end

execute 'ETL OS Locator' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'python OS_Locator_ETL.py'
end

execute 'ETL ONSPD' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'python ONSPD_ETL.py'
end

execute 'ETL Post towns' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'python OA_Posttowns.py'
end

execute 'Companies House downloader' do
  cwd '/home/openaddresses/etl/common-ETL'
  command 'python CH_download.py'
end
