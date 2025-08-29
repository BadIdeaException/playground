# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don"t change it unless you know what
# you"re doing.

USERNAME = 'vagrant'

# rubocop:disable Metrics
Vagrant.configure('2') do |config|
  config.vm.provider 'docker' do |docker|
    # Create ssh keys unless they are already created
    `ssh-keygen -f #{USERNAME}.key -t ed25519 -N ""` unless File.file?("#{USERNAME}.key")

    docker.build_dir = '.'
    docker.build_args = [
      # Make default user inside the VM have the same UID and GID as the user running the vagrant command
      # This makes it a lot easier working with shared code locations, because the user will own the files
      '--build-arg', "USERNAME=#{USERNAME}",
      '--build-arg', "UID=#{Process.uid}",
      '--build-arg', "GID=#{Process.gid}",
      '--build-arg', "KEYFILE=#{USERNAME}.key.pub"
    ]
    docker.has_ssh = true
    docker.remains_running = true
    # Use project"s directory name as name for the container.
    # (Note that this will fail if such a container already exists.)
    docker.name = File.dirname(__FILE__).split('/').last
    # Use container name as hostname inside the container, as is the default behavior for other providers.
    docker.create_args = ['--hostname', docker.name]
  end

  config.ssh.username = USERNAME
  config.ssh.private_key_path = "#{USERNAME}.key"

  # Expose port 9229 to allow debugging
  config.vm.network :forwarded_port, guest: 9229, host: 9229

  config.vm.provision 'shell', name: 'Install Ruby', env: { 'RUBY_VERSION' => '3.4.5' }, inline: <<-SHELL
    echo "Building Ruby v${RUBY_VERSION} from source."
    curl -L https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz | tar -xz -C /tmp
    cd "/tmp/ruby-${RUBY_VERSION}"
    ./configure
    make
    make install
  SHELL
  config.vm.provision 'shell', name: 'Install Bundler', privileged: false,
                               inline: "gem install bundler && bundle config set --local path '/vagrant/vendor/bundle'"

  config.vm.provision 'shell', name: 'Install aider', privileged: false,
                               inline: <<-SHELL
    sudo apt-get update && sudo apt-get install -y python3-pip
    python3 -m pip install --user aider-install
    /home/vagrant/.local/bin/aider-install
                               SHELL

  config.vm.provision 'file', source: '~/.aider.conf.yml',
                              destination: '/home/vagrant/.aider.conf.yml'

  config.ssh.extra_args = ['-t', 'cd /vagrant; bash --login']
end
# rubocop:enable Metrics
