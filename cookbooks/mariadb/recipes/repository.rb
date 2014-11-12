case node['platform']
when 'debian', 'ubuntu'
  install_method = 'apt'
when 'redhat', 'centos', 'fedora'
  install_method = 'yum'
end

if node['mariadb']['use_default_repository']
  case install_method
  when 'apt'
    include_recipe 'apt::default'

    apt_repository "mariadb-#{node['mariadb']['install']['version']}" do
      uri 'http://' + node['mariadb']['apt_repository']['base_url'] + '/' + \
          node['mariadb']['install']['version'] + '/' +  node['platform']
      distribution node['lsb']['codename']
      components ['main']
      keyserver 'keyserver.ubuntu.com'
      key '0xcbcb082a1bb943db'
    end
  when 'yum'
    include_recipe 'yum::default'

    yum_repository "mariadb-#{node['mariadb']['install']['version']}" do
      description 'MariaDB Official Repository'
      baseurl 'http://yum.mariadb.org/' + \
              node['mariadb']['install']['version'] + '/centos6-amd64'
      gpgkey 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB'
      action :create
    end

    # add the EPEL repo
    yum_repository 'epel' do
      description 'Extra Packages for Enterprise Linux'
      mirrorlist 'http://mirrors.fedoraproject.org/' \
                 'mirrorlist?repo=epel-6&arch=$basearch'
      gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
      action :create
    end
  else
  end
end
