#!/bin/bash

set -euf

echo "=============== Common stuff begun =============="

LOCALE="en_US.utf-8"

echo "Updating apt"
sudo apt-get update

echo "Set locale"
update-locale LANG="$LOCALE" LC_ALL="$LOCALE" LANGUAGE="$LOCALE"

echo "Installing Essentials"
sudo apt-get install -y libfftw3-dev libssl-dev libcurl4-openssl-dev libyaml-dev libxslt1-dev libxml2-dev libreadline-dev libpq-dev libffi-dev openssl autoconf build-essential software-properties-common python-software-properties

echo "Installing mail tools"
sudo apt-get install -y postfix heirloom-mailx

echo "Installing handy tools"
sudo apt-get install -y git-core vim ntp htop wget curl lsb-release ngrok-client ngrok-server

echo "Installing needed python things"
sudo apt-get install -y python-setuptools python-pycurl python-psycopg2

echo "Installing Java"
sudo apt-get install -y openjdk-7-jre-headless

DISTRIB_CODENAME=$(awk -F= '/DISTRIB_CODENAME=/{print $2}' /etc/lsb-release)

echo "=============== Common stuff done ==============="

echo "=============== SSH keys stuff begin ==============="

echo "Add Github as a known host"
sudo su vagrant -c "cp /tmp/config/known_hosts $HOME/.ssh/known_hosts"

echo "=============== SSH keys stuff done ==============="

echo "=============== Postgres stuff begun =============="

POSTGRES_VERSION=9.3

echo "Adding Postgres repository"
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $DISTRIB_CODENAME-pgdg main"
sudo apt-get update

echo "Installing Postgresql server and Client"
sudo apt-get install -y "postgresql-$POSTGRES_VERSION" "postgresql-contrib-$POSTGRES_VERSION"

echo "Installing Postgresql Host Based authentication file"
sudo cp /tmp/config/ruby/pg_hba.conf "/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"
sudo chown postgres:postgres "/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"

echo "Installing Postgresql Configuration file"
sudo cp /tmp/config/ruby/postgresql.conf "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
sudo chown postgres:postgres "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"

echo "Configure Postgresql to start at boot"
sudo update-rc.d postgresql enable

echo "Restaring Postgresql"
sudo /etc/init.d/postgresql restart

echo "Waiting for Postgresql to restart"
sleep 3

echo "Create vagrant role for Postgresql"
sudo su postgres -c 'createuser -s -d vagrant'

echo "=============== Postgres stuff end ================"

echo "=============== Redis stuff begin ===================="

echo "Installing Redis-Server"
sudo apt-get install -y redis-server

echo "Configure Redis-server to start at boot"
sudo update-rc.d redis-server enable

echo "Restaring Redis-server"
sudo /etc/init.d/redis-server restart

echo "Waiting for Redis-server to restart"
sleep 3

echo "=============== Redis stuff end ===================="

echo "=============== Phantomjs stuff begin ===================="

echo "Installing Phantomjs"

sudo apt-get install -y libicu52
sudo curl -Lo /usr/local/bin/phantomjs https://github.com/Pyppe/phantomjs2.0-ubuntu14.04x64/raw/master/bin/phantomjs
sudo chown vagrant:vagrant /usr/local/bin/phantomjs
sudo chmod +x /usr/local/bin/phantomjs

echo "=============== Phantomjs stuff end ===================="

echo "=============== Ruby stuff begin =================="

RBENV_VERSION=v0.4.0
RUBY_BUILD_VERSION=v20160111

RUBY_VERSION=2.3.0
BUNDLER_VERSION=1.11.2
LIQUID_VERSION=3.0.6

echo "Installing rbenv $RBENV_VERSION"
VAGRANT_HOME="/home/vagrant"
sudo su vagrant -c "git clone --branch $RBENV_VERSION git://github.com/sstephenson/rbenv.git $VAGRANT_HOME/.rbenv"

echo "Create rbenv directories with permissions"
sudo su vagrant -c "mkdir -p $HOME/.rbenv"
sudo su vagrant -c "chmod 0755 $HOME/.rbenv"
sudo su vagrant -c "mkdir -p $HOME/.rbenv/plugins"
sudo su vagrant -c "chmod 0755 $HOME/.rbenv/plugins"

echo "Installing ruby-build $RUBY_BUILD_VERSION"
sudo su vagrant -c "git clone --branch $RUBY_BUILD_VERSION git://github.com/sstephenson/ruby-build.git $VAGRANT_HOME/.rbenv/plugins/ruby-build"

echo "Installing and defaulting Ruby $RUBY_VERSION"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/bin/rbenv install $RUBY_VERSION"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/bin/rbenv global $RUBY_VERSION"

echo "Disable documentation for Ruby gems"
sudo su vagrant -c "cp /tmp/config/ruby/gemrc $HOME/.gemrc"

echo "Install Bundler $BUNDLER_VERSION"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/shims/gem install bundler -v $BUNDLER_VERSION"

echo "Rehashing rbenv"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/bin/rbenv rehash"

echo "Install Liquid $LIQUID_VERSION"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/shims/gem install liquid -v $LIQUID_VERSION"

echo "Configure bundler with libv8 & therubyracer"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/shims/bundle config build.libv8 --with-system-v8"
sudo su vagrant -c "$VAGRANT_HOME/.rbenv/shims/bundle config build.therubyracer --with-system-v8"

echo "Add more PATH to bashrc"
echo 'export PATH="/vagrant/bin:$PATH"' | cat - $VAGRANT_HOME/.bashrc > temp && mv temp $VAGRANT_HOME/.bashrc
echo 'eval "$(rbenv init -)"' | cat - $VAGRANT_HOME/.bashrc > temp && mv temp $VAGRANT_HOME/.bashrc
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' | cat - $VAGRANT_HOME/.bashrc > temp && mv temp $VAGRANT_HOME/.bashrc
sudo chown vagrant:vagrant $VAGRANT_HOME/.bashrc

echo "=============== Path stuff end ===================="
