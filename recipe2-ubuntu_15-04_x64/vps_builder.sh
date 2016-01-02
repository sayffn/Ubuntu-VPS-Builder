#!/bin/bash
# "Automated VPS Setup for Ubuntu 15.04 X64 - Rails with Nginx"
#
# Created by: Rafael Biriba - www.rafaelbiriba.com - biribarj@gmail.com
# https://github.com/rafaelbiriba/Ubuntu-VPS-Builder/
#
# USAGE: (Change vps_builder variables at the beggining of file if you want)
#
# $ chmod +x vps_builder.sh
# $ sudo ./vps_builder.sh yourdomain.com /app/path"

########################################
############### CONFIGS ################
DOMAIN=$1
APP_PATH=${2%/}
TIMEZONE="America/Sao_Paulo"

RUBY_ENABLED=true
BUNDLER_ENABLED=true
RUBY="ruby-2.0.0-p353" # Check correct version in http://ftp.ruby-lang.org/pub/ruby/2.0/

NGINX_ENABLED=true
NGINX="nginx-1.9.0" # Check correct version in http://nginx.org/download/
UNICORN_ENABLED=true

IPTABLES_ENABLED=true

MYSQL_SERVER_ENABLED=true
#######################################################
###################### Don't touch below ##############
RECIPEURL="https://raw.github.com/rafaelbiriba/Ubuntu-VPS-Builder/master/recipe2-ubuntu_15-04_x64"

echo "Updating before all"
echo "------------"
apt-get update && apt-get upgrade -y

echo "Set Hostname"
echo "------------"
echo $DOMAIN > /etc/hostname
echo "127.0.0.1 $1" >> /etc/hosts
hostname -F /etc/hostname

echo "Set Timezone"
echo "------------"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

echo "Install Essencials"
echo "------------------"
apt-get install build-essential git-core libcurl4-openssl-dev zlib1g-dev libssl-dev -y

if [ "$RUBY_ENABLED" = true ]; then
  echo "Install Ruby $RUBY"
  echo "------------------"
  mkdir ~/tmp && cd ~/tmp
  wget http://ftp.ruby-lang.org/pub/ruby/2.0/$RUBY.tar.gz
  tar xzvf $RUBY.tar.gz
  cd $RUBY
  ./configure --prefix=/usr/local --enable-shared --disable-install-doc --with-opt-dir=/usr/local/lib
  make
  make install
  cd ~
  rm -rf ~/tmp
fi

if [ "$BUNDLER_ENABLED" = true ]; then
  echo "Install gem bundler"
  echo "------------------"
  gem install bundler
fi

if [ "$NGINX_ENABLED" = true ]; then
  echo "Install Nginx"
  echo "---------------------------"
  mkdir ~/tmp && cd ~/tmp

  wget http://ftp.cs.stanford.edu/pub/exim/pcre/pcre-8.37.tar.gz
  tar xzvf pcre-8.37.tar.gz
  cd pcre-8.37
  ./configure && make && make install
  cd ~/tmp

  wget http://nginx.org/download/$NGINX.tar.gz
  tar xzvf $NGINX.tar.gz
  cd $NGINX
  ./configure --prefix=/etc/nginx && make && make install
  cd ~
  rm -rf ~/tmp

  mkdir -p /var/log/nginx/

  #### Patch for 64 bits, ignored by 32 bits ####
  sudo ln -s /usr/local/lib/libpcre.so.1 /usr/lib/libpcre.so.1

  cd ~
  wget $RECIPEURL/nginx-init.sh -O /etc/init.d/nginx
  chmod +x /etc/init.d/nginx
  /usr/sbin/update-rc.d -f nginx defaults
  /etc/init.d/nginx start

  cd ~
  wget $RECIPEURL/nginx-init.sh -O /etc/init.d/nginx
  chmod +x /etc/init.d/nginx
  /usr/sbin/update-rc.d -f nginx defaults

  cd ~
  wget $RECIPEURL/nginx.conf -O /etc/nginx/conf/nginx.conf
  mkdir /etc/nginx/sites-enabled
  wget $RECIPEURL/nginx-sitename -O /etc/nginx/sites-enabled/$DOMAIN

  sed -i -e "s/{{DOMAIN}}/$DOMAIN/g" /etc/nginx/sites-enabled/$DOMAIN
  sed -i -e "s/{{APP_PATH}}/$(echo $APP_PATH | sed -e 's/\//\\\//g')/g" /etc/nginx/sites-enabled/$DOMAIN
fi

if [ "$UNICORN_ENABLED" = true ]; then
  gem install unicorn

  INIT_FILE="/etc/init.d/unicorn-$DOMAIN"

  wget $RECIPEURL/unicorn-sitename-init -O $INIT_FILE

  sed -i -e "s/{{DOMAIN}}/$DOMAIN/g" $INIT_FILE
  sed -i -e "s/{{APP_PATH}}/$(echo $APP_PATH | sed -e 's/\//\\\//g')/g" $INIT_FILE
  chmod +x $INIT_FILE
  /usr/sbin/update-rc.d -f $INIT_FILE defaults
fi

if [ "$IPTABLES_ENABLED" = true ]; then
  echo "Configure iptables"
  echo "------------------"
  apt-get install iptables -y

  wget $RECIPEURL/iptables-config -O /etc/init.d/firewall

  chmod +x /etc/init.d/firewall
  update-rc.d firewall defaults 99
  /etc/init.d/firewall start
fi

if [ "$MYSQL_SERVER_ENABLED" = true ]; then
  echo "Install MySQL"
  echo "-------------"

  apt-get install mysql-server mysql-client libmysqlclient-dev -y
fi
