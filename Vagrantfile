require 'rbconfig'

Vagrant.require_version(">= 1.7.0")


Vagrant.configure("2") do |config|
  ram_slice_size = get_ram_slice_size
  config.vm.box = "harvard-dce/local-opsworks-ubuntu1404"
  config.vm.box_version = "1.2.0"


  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  # Ensure the repo is up-to-date on the first provisioning run
  config.vm.provision :shell,
    name: "update apt repo",
    inline: "apt-get update"

  # enable ubuntu esm
  config.vm.provision "esm", type: "shell" do |s|
    esm_token = ENV["UBUNTU_ESM_TOKEN"]
    if esm_token.nil? && provisioning?
      print "\nEnter your token to enable Ubuntu ESM, or [Enter] to skip: "
      esm_token = STDIN.gets.strip.chomp
    end
    if esm_token
      s.inline = "apt-get -y install ubuntu-advantage-tools && ua attach #{esm_token} && apt-get update && apt-get -y upgrade"
    end
  end

  config.vm.provision :shell,
    name: "kill agent updater",
    run: 'always',
    inline: %Q{for pid in `ps aux | grep opsworks-agent-updater | grep -v 'grep' | cut -f6 -d ' '`; do kill -9 $pid; done}

  config.vm.provision :shell,
    name: "disable agent updater",
    run: 'always',
    inline: %Q{rm -Rf /etc/cron.d/opsworks-agent-updater}

  config.vm.synced_folder "../dce-opencast", "/vagrant/dce-opencast"
  config.vm.synced_folder "../oc-opsworks-recipes", "/vagrant/oc-opsworks-recipes"

  config.vm.define "all-in-one" do |layer|
    layer.vm.hostname = "all-in-one1"

    layer.vm.provider :virtualbox do |vb|
      vb.memory = get_ram_slice_size * 10
      vb.cpus = 4
    end

    layer.vm.provision :opsworks, type:"shell", args: [
      'spec/support/opsworks-vm/all-in-one-stack.json',
      'spec/support/opsworks-vm/all-in-one-shared.json',
      'spec/support/opsworks-vm/all-in-one-setup.json'
    ]
    layer.vm.provision :deployment, type:"shell", run: 'always', args:[
      'spec/support/opsworks-vm/all-in-one-stack.json',
      'spec/support/opsworks-vm/all-in-one-shared.json',
      'spec/support/opsworks-vm/all-in-one-deploy.json'
    ]

    layer.vm.network "private_network", ip: "10.10.10.50"
  end

  config.vm.define "local-support" do |layer|
    register_multi_hosts(layer)
    layer.vm.hostname = "local-support1"
    layer.vm.provider :virtualbox do |vb|
      vb.memory = ram_slice_size * 2
      vb.cpus = 1
    end

    layer.vm.provision :opsworks, type:"shell", args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/local-support-shared.json',
      'spec/support/opsworks-vm/local-support-setup.json',
    ]
    layer.vm.provision :deployment, type:"shell", run: 'always', args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/local-support-shared.json',
      'spec/support/opsworks-vm/local-support-deploy.json'
    ]

    layer.vm.network "private_network", ip: "10.10.10.2"
  end

  config.vm.define "admin" do |layer|
    register_multi_hosts(layer)
    layer.vm.hostname = "admin1"
    layer.vm.provider :virtualbox do |vb|
      vb.memory = ram_slice_size * 3
      vb.cpus = 4
    end

    layer.vm.provision :opsworks, type:"shell", args: [
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/admin-shared.json',
      'spec/support/opsworks-vm/admin-setup.json'
    ]
    layer.vm.provision :deployment, type:"shell", run: 'always', args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/admin-shared.json',
      'spec/support/opsworks-vm/admin-deploy.json'
    ]

    layer.vm.network "private_network", ip: "10.10.10.10"
  end

  config.vm.define "engage" do |layer|
    register_multi_hosts(layer)
    layer.vm.hostname = "engage1"
    layer.vm.provider :virtualbox do |vb|
      vb.memory = ram_slice_size * 3
      vb.cpus = 4
    end

    layer.vm.provision :opsworks, type:"shell", args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/engage-shared.json',
      'spec/support/opsworks-vm/engage-setup.json'
    ]
    layer.vm.provision :deployment, type:"shell", args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/engage-shared.json',
      'spec/support/opsworks-vm/engage-deploy.json'
    ]

    layer.vm.network "forwarded_port", guest: 80, host: 8020
    layer.vm.network "private_network", ip: "10.10.10.20"
  end

  config.vm.define "workers" do |layer|
    register_multi_hosts(layer)
    layer.vm.hostname = "workers1"
    layer.vm.provider :virtualbox do |vb|
      vb.memory = ram_slice_size * 3
      vb.cpus = 4
    end
    layer.vm.provision :opsworks, type:"shell", args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/workers-shared.json',
      'spec/support/opsworks-vm/workers-setup.json'
    ]
    layer.vm.provision :deployment, type:"shell", args:[
      'spec/support/opsworks-vm/stack.json',
      'spec/support/opsworks-vm/workers-shared.json',
      'spec/support/opsworks-vm/workers-deploy.json'
    ]
    layer.vm.network "forwarded_port", guest: 80, host: 8030
    layer.vm.network "private_network", ip: "10.10.10.30"
  end
end

def register_multi_hosts(layer)
  layer.vm.provision :hosts do |provisioner|
    provisioner.add_host '10.10.10.2', ['local-support1.localdomain', 'local-support1']
    provisioner.add_host '10.10.10.10', ['admin1.localdomain', 'admin1']
    provisioner.add_host '10.10.10.20', ['engage1.localdomain', 'engage1']
    provisioner.add_host '10.10.10.30', ['workers1.localdomain', 'workers1']
  end
end

def is_osx?
  RbConfig::CONFIG['host_os'].match(/darwin|mac os/)
end

def get_ram_in_meg
  if is_osx?
    %x|sysctl hw.memsize|.gsub(/[^\d]/,'').to_i / 1024 / 1024
  else
    %x|grep MemTotal /proc/meminfo|.gsub(/[^\d]/,'').to_i / 1024
  end
end

def get_ram_slice_size
  # so we want to give:
  # 2 units of RAM to the storage / DB node
  # 3 units of RAM each to admin, engage, and the worker.
  # So split 40% the ram into eleven pieces.
  (get_ram_in_meg * 0.4).to_i / 11
end

def provisioning?
  (ARGV.include?("reload") && ARGV.include?("--provision")) || (ARGV.include?("up") && !ARGV.include?("--no-provision"))
end
