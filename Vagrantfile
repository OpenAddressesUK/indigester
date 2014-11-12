# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
api_key = YAML.load(File.open('.env'))['api_key']

Vagrant.configure('2') do |config|
  config.vm.define :indigester do |config|
    config.vm.box      = 'ffuenf/ubuntu-14.10-server-amd64'
    config.vm.hostname = 'indigester'

    config.vm.provider "virtualbox" do |v|
      v.memory =4096
    end

    config.vm.provision :shell, :inline => 'apt-get update'

    config.vm.provision 'chef_solo' do |chef|
      chef.add_recipe 'chef-etl-ingester'

      chef.json = {
        'ernest_api_key' => api_key
      }
    end
  end
end
