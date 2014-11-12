require 'spec_helper'

describe package 'git' do
  it { should be_installed }
end

describe package 'python-mysqldb' do
  it { should be_installed }
end

describe package 'mariadb-server' do
  it { should be_installed }
end

describe service 'mysql' do
  it { should be_running }
end

describe user 'openaddresses' do
  it {should exist }
end

describe file '/home/openaddresses/etl/common-ETL' do
  it { should be_directory }
end

describe file '/home/openaddresses/etl/common-ETL/setup.py' do
  its(:content) { should match /name='common_etl',/ }
end

describe file '/home/openaddresses/etl/companies-house-ETL' do
  it { should be_directory }
end

describe file '/home/openaddresses/etl/companies-house-ETL/README.md' do
  its(:content) { should match /companies-house-ETL/ }
end

describe command 'mysql -e "show databases"' do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match /Database/ }
end

describe command 'mysql -e "show databases"' do
  its(:stdout) { should match /commonetldb/ }
end

describe command 'mysql commonetldb -e "show tables"' do
  its(:stdout) { should match /ONSPD_Changes/ }
  its(:stdout) { should match /Posttowns/ }
end

describe file '/home/openaddresses/etl/common-ETL/oa_alpha_etl.cnf' do
  it { should be_file }
  its(:content) { should match /hostname=localhost/ }
  its(:content) { should match /database=commonetldb/ }
  its(:content) { should match /username=root/ }
  its(:content) { should match /password=\n/ }
  its(:content) { should match /token=thisisakey/ }
end

describe file '/home/openaddresses/etl/common-ETL/OS_Locator2014_2_OPEN_xad.txt' do
  it { should be_file }
end

describe file '/home/openaddresses/etl/common-ETL/ONSPD_AUG_2014.csv' do
  it { should be_file }
end

describe command 'mysql -e "SELECT COUNT(*) FROM commonetldb.OS_Locator"' do
  its(:stdout) { should match /[0-9]{6,}/ }
end

describe command 'mysql -e "SELECT COUNT(*) FROM commonetldb.ONSPD"' do
  its(:stdout) { should match /[0-9]{7,}/ }
end

describe command 'mysql -e "SELECT COUNT(*) FROM commonetldb.ONSPD_Changes"' do
  its(:stdout) { should match /[0-9]{6,}/ }
end

describe command 'mysql -e "SELECT COUNT(*) FROM commonetldb.Posttowns"' do
  its(:stdout) { should match /[0-9]{4,}/ }
end

describe file '/home/openaddresses/etl/common-ETL/BasicCompanyData-2014-11-01-part5_5.csv' do
  it { should be_file }
end
