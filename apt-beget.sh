#!/usr/bin/env bash
# URL: https://github.com/ford153focus/apt-beget
function apt_localinstall {
    check_d

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    mkdir -p $HOME/.beget/tmp/dpkg
    cd $HOME/.beget/tmp/dpkg || exit

    #download
    echo_y "Downloading..."
    apt-get --print-uris --yes -d --reinstall install $1 | grep ^\'http:\/\/ | awk '{print $1}'| xargs wget

    #install
    echo_y "Installing..."
    find . -name '*.deb' -exec dpkg -x {} "$HOME/.beget/tmp/dpkg" \;
    
    echo_y "Setting up..."
    rsync -a $HOME/.beget/tmp/dpkg/usr/ $HOME/.local/
    echo 'export LD_LIBRARY_PATH=~/.local/lib/:~/.local/lib/x86_64-linux-gnu' >> $HOME/.bashrc
}

function check_d {
    if [ "$(cat /proc/self/cgroup | grep cpuset | grep docker -c)" -ne 1 ]
    then
         echo_r "Please launch this script in docker"
         exit 1
    fi
}

function check_s {
    if [ "$(whoami | grep _ -c)" == '0' ]
    then
        echo_r "Please launch this script in siteuser"
        exit 1
    fi
}

function check_ds {
    check_d
    check_s
}


:<<=
==print text with green color. Usually for success messages
=
function echo_g {
    echo -e "\n\e[1m\e[48;5;28m $1 \e[0m\n"
}

:<<=
==print text with red color. Usually for error messages
=
function echo_r {
    echo -e "\n\e[1m\e[48;5;1m $1 \e[0m\n"
}

:<<=
==print text with yellow color. Usually for information messages
=
function echo_y {
    echo -e "\n\e[1m\e[48;5;11m\e[30m $1 \e[0m\n"
}


:<<=
==create common folders that we are will store temporary files and end result
=
function prepare_folders {
  mkdir -p "$HOME"/.beget/tmp
  mkdir -p "$HOME"/.local/opt
  mkdir -p "$HOME"/.local/bin

  rm -rf "$HOME"/.beget/tmp/*
  rm -rf "$HOME"/.beget/tmp/.*

  cd "$HOME/.beget/tmp" || exit
}


function installer_help {
    echo "
Beget Install Tool.

We can install to .local of user next tools:
 - composer
 - cwebp & dwebp
 - django (MVC-Framework for web written in Python)
 - drush (CLI-tools for maintain Drupal CMS)
 - ewww (compilation of graphic utils)
 - ghostscript
 - gifsicle
 - git
 - gmagick (php extension)
 - graphicsmagick
 - htop
 - jpegoptim & jpegtran
 - joomlatools (CLI-tools for maintain Joomla CMS)
 - nodejs (with simple hello world)
 - opencart (fresh version from github)
 - optipng
 - pdfinfo
 - phantomjs
 - phpexpress (php module, only for php 5.3)
 - pngquant
 - pma (non-buggy PhpMyAdmin 4.5 for install on subdomain)
 - ror (Ruby On Rails, MVC-Framework for web written in Ruby)
 - wpcli (CLI-tools for maintain WordPress CMS)

Usage: beget_install \$tool
"
}


:<<=
==install any extension from pecl
===https://pecl.php.net/
=
function install_from_pecl {
    check_ds
    echo_y "Installing $1..."

    #collect info
    if [ -z $1 ]
    then
        echo_r "Define extension (format: extension-0.0.0.tgz)"
        exit 1
    fi

    if [[ "$1" =~ ^[a-z]+\-[0-9]+\.[0-9]+\.[0-9]+.*\.tgz$ ]]
    then
        true
    else
        echo_r "Define extension (format: extension-0.0.0.tgz)"
        exit 1
    fi

    if [ -z $2 ]
    then
        echo_r "Define PHP version (format 5.6)"
        exit 1
    fi

    if [[ $2 =~ ^[0-9]\.[0-9]$ ]]
    then
        true
    else
        echo_r "Define PHP version (format 5.6)"
        exit 1
    fi

    ext_name=$(/usr/local/php-cgi/5.6/bin/php -r '$a=explode("-",$argv[1]);print_r($a[0]);' $1)
    ext_ver=$(/usr/local/php-cgi/5.6/bin/php -r '$a=explode("-",$argv[1]);print_r(pathinfo($a[1])["filename"]);' $1)

    prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp || exit
    curl -Lk "https://pecl.php.net/get/$1" > $1
    if [ ! -f "$HOME/.beget/tmp/$1" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf $1
    if [ ! -d "$HOME/.beget/tmp/$ext_name-$ext_ver" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    PATH=$PATH:/usr/local/php-cgi/$2/bin/

    mkdir -p "$HOME/.local/lib/php/$2/"
    
    cd "$HOME/.beget/tmp/$ext_name-$ext_ver" || exit
    phpize
    ./configure --prefix="$HOME/.local/lib/php/$2/"
    make
    make install #ignore fail
    
    cp -f "$HOME/.beget/tmp/$ext_name-$ext_ver/modules/$ext_name.so" "$HOME/.local/lib/php/$2/"

    if [ ! -f "$HOME/.local/lib/php/$2/$ext_name.so" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #install
    echo_y "Installing..."
    if [ ! -f "$HOME/public_html/cgi-bin/php.ini" ]
    then
        mkdir -p $HOME/public_html/cgi-bin/
        cp /etc/php/cgi/$2/php.ini $HOME/public_html/cgi-bin/php.ini
    fi
    sed -i 's/; EOF//g' $HOME/public_html/cgi-bin/php.ini
    printf "\n\n[PHP]\nextension = $HOME/.local/lib/php/$2/$ext_name.so" >> $HOME/public_html/cgi-bin/php.ini

    echo '<?php phpinfo();' > $HOME/public_html/x.php

    #finish
    echo_g "Extension $ext_name installed"
    echo_g "Dont forget to switch PHP to cgi"    
}


:<<=
==asciidoc
=
function install_asciidoc {
    check_d
    echo_y "Installing asciidoc..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders
    
    #depencies
    echo_y "Satisfaying depencies..."
    install_libxml2
    install_libxslt

    #cloning
    echo_y "Cloning..."
    cd $HOME/.beget/tmp || exit
    git clone https://github.com/asciidoc/asciidoc.git
    if [ ! -d "$HOME/.beget/tmp/asciidoc" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi
    
    #compilation
    echo_y "Compilating..."
    cd asciidoc || exit
    autoconf
    ./configure --prefix=$HOME/.local
    sed -i 's/\-\-nonet\s\-\-noout/\-\-noout/g' ./a2x.py
    make
    make install
    if [ ! -f "$HOME/.local/bin/asciidoc" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "default installed"
}


:<<=
==Composer
===Dependency Manager for PHP
===https://getcomposer.org
===https://github.com/composer/composer
=
function install_composer {
    echo_y "Installing Composer..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #install
    echo_y "Installing..."
    mkdir $HOME/.local/opt/composer/
    cd "$HOME/.local/opt/composer/" || exit
    curl -sS https://getcomposer.org/installer | /usr/local/php-cgi/5.6/bin/php
    if [ -f "$HOME/.local/opt/composer/composer.phar" ]
    then
        echo "/usr/local/php-cgi/5.6/bin/php -dshort_open_tag=On -ddate.timezone='Europe/Moscow' $HOME/.local/opt/composer/composer.phar \$@" > $HOME/.local/bin/composer
        chmod +x "$HOME/.local/bin/composer"
        composer config -g github-oauth.github.com  3f1c1a81d81f714de917e068b309e76df908cadf
    else
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #finish
    echo_g "Composer installed"
}


function install_cwebp {
    check_d
    echo_y "Installing Cwebp..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Cloning repo..."
    git clone https://github.com/webmproject/libwebp.git
    if [ ! -d "$HOME/.beget/tmp/libwebp" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi

    #compile
    echo_y "Compiling..."
    cd "$HOME/.beget/tmp/libwebp" || exit
    ./autogen.sh
    ./configure --prefix=$HOME/.local
    make -j "$(expr $(nproc) / 21)"
    make install
    if [ ! -f "$HOME/.local/bin/cwebp" ]
    then
        echo_r "Seems like compilation is failed"
        exit 1
    fi

    echo_g "Cwebp installed"
}


:<<=
==Django
=
function install_django {
    check_ds
    echo_y "Installing Django..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_python3

    #install
    echo_y "Installing..."
    pip3 install django --user --ignore-installed

    echo_y "Creating project..."
    cd "$HOME" || exit
    "$HOME/.local/bin/python3" "$HOME/.local/bin/django-admin.py" startproject HelloDjango --verbosity 3

    echo_y "Setting up..."
    echo "# -*- coding: utf-8 -*-
import os, sys
#project directory
sys.path.insert(0, '$HOME/HelloDjango')
sys.path.insert(1, '$HOME/.local/lib/python3.6/site-packages')
#project settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'HelloDjango.settings')
#start server
from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()" > $HOME/HelloDjango/passenger_wsgi.py

    echo "PassengerEnabled On
PassengerAppRoot $HOME/HelloDjango
PassengerPython  $HOME/.local/bin/python3" > $HOME/.htaccess

    target_directory="$(basename $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ))"
    sed -i "s/ALLOWED_HOSTS\s=\s\[\]/ALLOWED_HOSTS = \['$target_directory'\]/g" $HOME/HelloDjango/HelloDjango/settings.py
    echo_y "Edit 'ALLOWED_HOSTS' in $HOME/HelloDjango/HelloDjango/settings.py if domain name is different from"

    mkdir -p $HOME/tmp
    touch    $HOME/tmp/restart.txt

    #finish
    echo_g "Django installed"
}


:<<=
==DRUPAL CONSOLE
===https://drupalconsole.com/
=
function install_drupalconsole {
    check_ds
    echo_y "Installing default..."

    #download
    echo_y "Downloading..."
    cd $HOME/.local/opt/
    curl -Lk https://drupalconsole.com/installer -o drupal.phar
    if [ ! -f "$HOME/.local/opt/drupal.phar" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    echo "/usr/local/php-cgi/5.6/bin/php -dshort_open_tag=On -ddate.timezone='Europe/Moscow' $HOME/.local/opt/drupal.phar \$@" > $HOME/.local/bin/drupal
    chmod +x $HOME/.local/bin/drupal
    drupal self-update
    drupal

    #finish
    echo_g "default installed"
}


:<<=
==Drupal 7
===https://www.drupal.org/
=
function install_drupal_7 {
    check_s
    echo_y "Installing Drupal 7..."

    #collecting install information
    echo_y 'ENTER admin account mail (default is "admin@example.com")'
    read account_mail
    if [[ ! $account_mail ]]
    then
        account_mail=`whoami`
    fi

    echo_y 'ENTER admin account name (default is current account login)'
    read account_name
    if [[ ! $account_name ]]
    then
        account_name=`whoami`
    fi

    echo_y 'ENTER account pass (default is "fordfocus")'
    read account_pass
    if [[ ! $account_pass ]]
    then
        account_pass='fordfocus'
    fi

    echo_y 'ENTER database name (default is "root")'
    read db_name
    if [[ ! $db_name ]]
    then
        db_name=`whoami`
    fi

    echo_y 'ENTER database pass (default is "fordfocus")'
    read db_pass
    if [[ ! $db_pass ]]
    then
        db_pass='fordfocus'
    fi

    echo_y 'ENTER site mail (for outgoing mail) (default is "admin@example.com")'
    read site_mail
    if [[ ! $site_mail ]]
    then
        site_mail='admin@example.com'
    fi

    echo_y 'ENTER site name (default is "My site")'
    read site_name
    if [[ ! $site_name ]]
    then
        site_name='My site'
    fi

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_drush 7.x-dev

    #install
    PATH=$PATH:/usr/local/php-cgi/5.6/bin
    PATH=$PATH:~/.composer/vendor/bin/

    echo_y "Installing..."
    cd $HOME
    folder_name=${PWD##*/}

    echo_y "Creating project..."
    rm -rf ~/public_html/
    drush dl drupal-7.x --drupal-project-rename='public_html'

    echo_y "Setting up..."
    cd public_html
    #drush site-install standard --locale=ru --db-url='sqlite://../db.sqlite' --site-name="$site_name" --account-name=`whoami` --account-pass=fordfocus
    drush site-install standard \
        --account-mail="$account_mail" --account-name="$account_name" --account-pass="$account_pass" \
        --db-url="mysql://$db_name:$db_pass@localhost/$db_name" --locale=ru-RU \
        --site-mail="$site_mail" --site-name="$site_name"

    #finish
    echo_g "Drupal 7 installed"
}

:<<=
==Drupal 8
===https://www.drupal.org/
=
function install_drupal_8 {
    check_s
    echo_y "Installing Drupal 8..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_drush 8.x-dev
    PATH=$PATH:/usr/local/php-cgi/7.1/bin

    #install
    echo_y "Installing..."
    cd ~
    folder_name=${PWD##*/}
    echo_y "Creating project..."
    drush dl drupal --drupal-project-rename='public_html'
    echo_y "Setting up..."
    cd public_html
    #drush site-install standard --locale=ru --db-url='sqlite://../db.sqlite' --site-name="$folder_name" --account-name=`whoami` --account-pass=fordfocus

    #finish
    echo_g "Drupal 8 installed"
}


:<<=
==drush
===http://www.drush.org/
=
function install_drush {
    echo_y "Installing drush..."

    #collecting install information
    if [[ ! $1 ]]
    then
        echo_y "Choose the version..."
        composer show -a "drush/drush" | grep versions
        read drush_version
        if [[ ! $drush_version ]]
        then
            drush_version='dev-master'
        fi
    else
        drush_version=$1
    fi


    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer

    #install
    echo_y "Installing..."
    echo_y "Version set to $1"
    composer global require "drush/drush:$drush_version"

    #finish
    echo_g "drush installed"
}


:<<=
==EWWW utils and patch
===https://wordpress.org/plugins/ewww-image-optimizer/
=
function install_ewww {
    check_ds
    echo_y "Installing EWWW utils and patch..."

    #depencies
    echo_y "Satisfaying depencies..."
    install_jpegtran
    install_optipng
    install_pngout #optional dep
    install_gifsicle
    install_cwebp

    #install
    echo_y "Setting up..."
    cp $HOME/public_html/wp-content/plugins/ewww-image-optimizer/unique.php $HOME/public_html/wp-content/plugins/ewww-image-optimizer/unique.php.bak

    ##turn off updater
    str=$(grep -n 'function ewww_image_optimizer_install_tools() {' $HOME/public_html/wp-content/plugins/ewww-image-optimizer/unique.php | /usr/local/php-cgi/5.6/bin/php -r '$t1=trim(fgets(STDIN));$t2=explode(":",$t1);$t3=$t2[0];$t4=(int)$t3+1;echo($t4);')
    sed -i $str'i\        return false;\' $HOME/public_html/wp-content/plugins/ewww-image-optimizer/unique.php

    ##put `~/.local/bin` instead of all
    str=$(grep -n 'ewww_image_optimizer_tool_found( $binary, $switch )' $HOME/public_html/wp-content/plugins/ewww-image-optimizer/unique.php | /usr/local/php-cgi/5.6/bin/php -r '$t1=trim(fgets(STDIN));$t2=explode(":",$t1);$t3=$t2[0];echo($t3);')
    sed -i $str'i\        return $_SERVER["DOCUMENT_ROOT"]."/../.local/bin/".$binary;\' $HOME/public_html/wp-content/plugins/ewww-image-optimizer/unique.php

    ln -sf $HOME/.local/bin/pngout $HOME/.local/bin/pngout-static #wp-content/plugins/ewww-image-optimizer/unique.php:785

    #finish
    echo_g "EWWW utils and patch installed"
}


:<<=
==flask
=
function install_flask {
    check_ds
    echo_y "Installing flask..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_python3

    #install
    echo_y "Installing..."
    pip3 install flask --user --ignore-installed
    
    echo_y "Creating project..."
    mkdir -p $HOME/HelloFlask    
    echo "# -*- coding: utf-8 -*-
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello Flask!'

if __name__ == '__main__':
    app.run()" > $HOME/HelloFlask/__init__.py

    echo "# -*- coding: utf-8 -*-
import os, sys
#project directory
sys.path.insert(0, '$HOME/Helloflask')
sys.path.insert(1, '$HOME/.local/lib/python3.6/site-packages')

from HelloFlask import app as application # когда Flask стартует, он ищет application. Если не указать 'as application', сайт не заработает
from werkzeug.debug import DebuggedApplication # Опционально: подключение модуля отладки
application.wsgi_app = DebuggedApplication(application.wsgi_app, True) # Опционально: включение модуля отадки
application.debug = False  # Опционально: True/False устанавливается по необходимости в отладке" > $HOME/passenger_wsgi.py

    echo_y "Setting up..."
    echo "PassengerEnabled On
PassengerPython  $HOME/.local/bin/python3" > $HOME/.htaccess

    ln -s public_html public    
    
    mkdir -p $HOME/tmp
    touch    $HOME/tmp/restart.txt

    #finish
    echo_g "flask installed"
}

function install_ghostscript {
    echo_y "Installing Ghostscript..."

    prepare_folders
    cd $HOME/.beget/tmp

    echo_y "Downloading tarball"
    curl -Lk https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs919/ghostscript-9.19-linux-x86_64.tgz > $HOME/.beget/tmp/ghostscript-9.19-linux-x86_64.tgz
    if [ ! -f "$HOME/.beget/tmp/ghostscript-9.19-linux-x86_64.tgz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    echo_y "Unpacking tarball"
    tar xvf ghostscript-9.19-linux-x86_64.tgz
    if [ ! -d "$HOME/.beget/tmp/ghostscript-9.19-linux-x86_64" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    mv $HOME/.beget/tmp/ghostscript-9.19-linux-x86_64 $HOME/.local/opt/
    ln -sf $HOME/.local/opt/ghostscript-9.19-linux-x86_64/gs-919-linux_x86_64 $HOME/.local/bin/ghostscript
    ln -sf $HOME/.local/opt/ghostscript-9.19-linux-x86_64/gs-919-linux_x86_64 $HOME/.local/bin/gs
    echo_g "Ghostscript installed"
}


:<<=
==Ghost
===Something like wordpress, but built with node.js
===https://ghost.org/
=
function install_ghost {
    check_ds
    echo_y "Installing Ghost..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_nodejs_6_lts

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -L https://ghost.org/zip/ghost-latest.zip -o ghost.zip
    if [ ! -f "$HOME/.beget/tmp/ghost.zip" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    mkdir $HOME/ghost
    unzip -uo ghost.zip -d $HOME/ghost
    if [ ! -d "$HOME/ghost" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    echo "PassengerNodejs $HOME/.local/opt/node-v6.9.4-linux-x64/bin/node
PassengerAppRoot $HOME/ghost
PassengerAppType node
PassengerStartupFile app.js" > $HOME/.htaccess 
    cd $HOME/ghost
    npm install -g grunt-cli
    npm install --production
    npm start --production
    mkdir -p $HOME/tmp
    touch $HOME/tmp/restart.txt

    #finish
    echo_g "Ghost installed"
}


:<<=
==gifsicle
===https://github.com/kohler/gifsicle
=
function install_gifsicle {
    check_d
    echo_y "Installing gifsicle..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk http://www.lcdf.org/gifsicle/gifsicle-1.88.tar.gz > gifsicle.tar.gz
    if [ ! -f "$HOME/.beget/tmp/gifsicle.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf gifsicle.tar.gz
    if [ ! -d "$HOME/.beget/tmp/gifsicle-1.88" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    cd $HOME/.beget/tmp/gifsicle-1.88
    aclocal
    automake --add-missing
    autoconf
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ ! -f "$HOME/.local/bin/gifsicle" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "gifsicle installed"
}


:<<=
==Git
=
function install_git {
    check_ds
    echo_y "Installing Git..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders
    
    #depencies
    echo_y "Satisfaying depencies..."

    #cloning
    echo_y "Cloning..."
    cd $HOME/.beget/tmp
    git clone https://github.com/git/git
    if [ ! -d "$HOME/.beget/tmp/git" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi
    
    #compilation
    echo_y "Compilating..."
    cd git
    make configure
    ./configure --prefix=$HOME/.local
    make install
    if [ ! -f "$HOME/.local/bin/git" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "Git installed"
}


:<<=
==gmagick
===http://www.graphicsmagick.org/index.html
===https://pecl.php.net/package/gmagick
=
function install_gmagick {
    check_ds
    echo_y "Installing gmagick..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders
   
    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk https://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.25/GraphicsMagick-1.3.25.tar.gz > GraphicsMagick-1.3.25.tar.gz
    if [ ! -f "$HOME/.beget/tmp/GraphicsMagick-1.3.25.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf GraphicsMagick-1.3.25.tar.gz 
    if [ ! -d "$HOME/.beget/tmp/GraphicsMagick-1.3.25" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    cd GraphicsMagick-1.3.25
    export CXXFLAGS="$CXXFLAGS -fPIC"
    ./configure --prefix=$HOME/.local --enable-shared
    make -j $(expr $(nproc) / 21)
    make install
    make check
    if [ ! -f "$HOME/.local/bin/gm" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk curl https://pecl.php.net/get/gmagick-1.1.7RC3.tgz > gmagick-1.1.7RC3.tgz
    if [ ! -f "$HOME/.beget/tmp/gmagick-1.1.7RC3.tgz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf gmagick-1.1.7RC3.tgz
    if [ ! -d "$HOME/.beget/tmp/gmagick-1.1.7RC3" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    PATH=$PATH:/usr/local/php-cgi/5.6/bin/
    mkdir -p $HOME/.local/lib/php/56/
    cd gmagick-1.1.7RC3/
    phpize
    ./configure --prefix=$HOME/.local/lib/php/56/ --with-gmagick=$HOME/.local
    make -j $(expr $(nproc) / 21)
    cp modules/gmagick.so $HOME/.local/lib/php/56/
    if [ ! -f $HOME/.local/lib/php/56/gmagick.so ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #install
    echo_y "Installing..."
    if [ ! -f "$HOME/public_html/cgi-bin/php.ini" ]
    then
        mkdir -p $HOME/public_html/
        cp /etc/php/cgi/5.6/php.ini $HOME/public_html/cgi-bin/php.ini
    fi
    sed -i 's/; EOF//g' $HOME/public_html/cgi-bin/php.ini
    printf "\n\n[PHP]\nextension = $HOME/.local/lib/php/56/gmagick.so" >> $HOME/public_html/cgi-bin/php.ini

    #finish
    echo_g "gmagick installed"
}


:<<=
==htop
===https://github.com/hishamhm/htop
=
function install_htop {
    echo_y "Installing Htop..."

    #prepare folders
    prepare_folders
    rm -rf $HOME/.beget/tmp/htop
    cd $HOME/.beget/tmp

    #download
    echo_y "Cloning repo"
    git clone https://github.com/hishamhm/htop.git
    if [ ! -d "$HOME/.beget/tmp/htop" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi

    #compile
    echo_y "Compiling..."
    cd $HOME/.beget/tmp/htop
    ./autogen.sh
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ -f "$HOME/.local/bin/htop" ]
    then
        echo_g "htop installed"
    else
        echo_r "Seems like compilation is failed"
        exit 1
    fi
}


:<<=
==analog of wp-cli for Joomla
==https://github.com/joomlatools/joomlatools-console
=
function install_joomlatools {
    echo_y "Installing joomlatools..."

    #prepare folders
    prepare_folders

    #depencies
    install_composer

    #download
    composer global require joomlatools/console

    #install
    printf "\n\nPATH=$PATH:~/.composer/vendor/bin\n" >> $HOME/.bashrc
    source $HOME/.bashrc
    echo_y 'Now execute `source $HOME/.bashrc`'

    echo_g "joomlatools installed"
}


:<<=
==jpegoptim
===https://github.com/tjko/jpegoptim
=
function install_jpegoptim {
    check_d
    echo_y "Installing jpegoptim..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #cloning
    echo_y "Cloning..."
    cd $HOME/.beget/tmp
    git clone https://github.com/tjko/jpegoptim.git
    if [ ! -d "$HOME/.beget/tmp/jpegoptim" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    cd jpegoptim
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make strip
    make install
    if [ ! -f "$HOME/.local/bin/jpegoptim" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "jpegoptim installed"
}


function install_jpegtran {
    check_d
    echo_y "Installing Jpegtran..."

    #prepare folders
    prepare_folders
    rm -rf $HOME/.beget/tmp/jpegtran
    cd $HOME/.beget/tmp

    #download
    echo_y "Cloning repo"
    git clone https://github.com/cloudflare/jpegtran.git
    if [ ! -d "$HOME/.beget/tmp/jpegtran" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi

    #compile
    echo_y "Compiling..."
    cd $HOME/.beget/tmp/jpegtran
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ -f "$HOME/.local/bin/jpegtran" ]
    then
        echo_g "jpegtran installed"
    else
        echo_r "Seems like compilation is failed"
        exit 1
    fi
}


:<<=
==Laravel
=
function install_laravel {
    check_ds
    echo_y "Installing Laravel..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer
#    install_nodejs

    #install
    echo_y "Installing..."
    cd ~
    rm -rf ~/public_html

    echo "/usr/local/php-cgi/7.1/bin/php -c $HOME/.local/etc/php.ini \$@" > $HOME/.local/bin/php
    chmod +x $HOME/.local/bin/php

#    composer create-project --prefer-dist laravel/laravel public_html
    composer global require "laravel/installer"
    PATH=$PATH:~/.composer/vendor/bin/
    laravel new . --force
    ln -s public public_html
    cp .env.example .env
    ./artisan key:generate
    ./artisan config:clear

    #finish
    echo_g "Laravel installed"
}


function install_libsmbclient {
    check_ds
    prepare_folders
    
    cd $HOME/.beget/tmp
    
    apt-get --print-uris --yes install libsmbclient-dev | grep ^\' | cut -d\' -f2 | xargs wget
    find . -name '*.deb' -exec ar vx {} \; && tar -xvf data* -C $HOME/.local/
    
    git clone git://github.com/eduardok/libsmbclient-php.git
    cd libsmbclient-php
    /usr/local/php-cgi/5.6/bin/phpize
    sed -i "s/for i in \/usr\/local\/include/for i in ~\/.local\/usr\/include \/usr\/local\/include/g" ./configure

    
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/usr/lib/x86_64-linux-gnu/
    export LIBRARY_PATH=$LIBRARY_PATH:$HOME/.local/usr/lib/x86_64-linux-gnu/      
    LD_LIBRARY_PATH=$HOME/.local/usr/lib/x86_64-linux-gnu/ ./configure --with-php-config=/usr/local/php-cgi/5.6/bin/php-config
    make -j $(expr $(nproc) / 21)
    make install INSTALL_ROOT=$HOME/.local
    printf "\n\n[PHP]\nextension = `find $HOME -name 'smbclient.so'|grep cgi|head -n 1`" >> $HOME/public_html/cgi-bin/php.ini
    printf "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/.local/usr/lib/x86_64-linux-gnu/\nexport LIBRARY_PATH=$LIBRARY_PATH:$HOME/.local/usr/lib/x86_64-linux-gnu/" >> $HOME/.profile
}


:<<=
==LXML 2
=
function install_libxml2 {
    check_ds
    echo_y "Installing Git..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #cloning
    echo_y "Cloning..."
    cd $HOME/.beget/tmp
    git clone git://git.gnome.org/libxml2
    if [ ! -d "$HOME/.beget/tmp/libxml2" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi
    
    #compilation
    echo_y "Compilating..."
    cd libxml2
    ./autogen.sh --prefix=$HOME/.local --disable-shared
    ./configure --prefix=$HOME/.local
    make
    make install
    if [ ! -f "$HOME/.local/bin/xmllint" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "default installed"
}


:<<=
==libxslt
=
function install_libxslt {
    check_ds
    echo_y "Installing Git..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #cloning
    echo_y "Cloning..."
    cd $HOME/.beget/tmp
    git clone https://git.gnome.org/browse/libxslt
    if [ ! -d "$HOME/.beget/tmp/libxslt" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi
    
    #compilation
    echo_y "Compilating..."
    cd libxslt
    ./autogen.sh --prefix=$HOME/.local --disable-shared
    ./configure --prefix=$HOME/.local
    make
    make install
    if [ ! -f "$HOME/.local/bin/xsltproc" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "default installed"
}


function install_magento_ce {
    check_ds
    cd $HOME
    echo_y "Installing Magento Community Edition"
    rm -rf public_html
    install_composer
    echo '
{
    "http-basic": {
        "repo.magento.com": {
            "username": "64340d061f552490037f32bca3312fe9",
            "password": "f10a4560fe116e464496e77f56b4e2f3"
        }
    }
}' > $HOME/.composer/auth.json
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition public_html
    curl -Lk 'http://api.beget.ru/api/domain/changePhpVersion?login=ford153&passwd=password&full_fqdn=1.ce.2.magento.ford153.bget.ru&php_version=5.6&is_cgi=0&output_format=json'
    curl -Lk 'http://api.beget.ru/api/domain/addDirectives?login=ford153&passwd=password&input_format=json&output_format=json&input_data={"full_fqdn":"1.ce.2.magento.ford153.bget.ru","directives_list":[{"name":"php_admin_value","value":"always_populate_raw_post_data -1"}]}'

    echo_g "Files downloaded, now go to site and launch installation"
}

function install_magento_ee {
    check_ds
    cd $HOME
    echo_y "Installing Magento Enterprise Edition"
    echo_y "\n\nUse 64340d061f552490037f32bca3312fe9 for login and f10a4560fe116e464496e77f56b4e2f3 for password" # via https://marketplace.magento.com # login - support@beget.ru # password - BeGet120686
    rm -rf public_html
    install_composer
    composer create-project --repository-url=https://repo.magento.com/ magento/project-enterprise-edition public_html
    echo_g "Files downloaded, now go to site and launch installation"
}


function install_ncdu {
    check_d
    echo_y "Installing default..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk http://dev.yorhel.nl/download/ncdu-1.12.tar.gz > ncdu-1.12.tar.gz
    if [ ! -f "$HOME/.beget/tmp/ncdu-1.12.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf ncdu-1.12.tar.gz
    if [ ! -d "$HOME/.beget/tmp/ncdu-1.12" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    cd ncdu-1.12
    aclocal
    autoconf
    autoheader
    automake --add-missing
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ ! -f "$HOME/.local/bin/ncdu" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "NCDU installed"
}


:<<=
==newscoop
===Newscoop is the open content management system for professional journalists
===https://www.sourcefabric.org/en/newscoop/
===https://github.com/sourcefabric/Newscoop/
=
function install_newscoop {
    check_ds
    echo_y "Installing newscoop..."

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer

    #install
    echo_y "Installing..."
    cd $HOME
    rm -rf public_html
    echo_y "Creating project..."
    composer create-project sourcefabric/newscoop ~/newscoop -s dev
    
    cd newscoop/newscoop/
    composer install
    
    #echo_y "ENTER DATABASE NAME"
    #read dname
    #echo_y "ENTER DATABASE PASSWORD"
    #read dpw
    #mkdir -p ~/newscoop/newscoop/cache/prod/annotations
    #chmod 777 ~/newscoop/newscoop/cache/prod/annotations
    #/usr/local/php-cgi/5.6/bin/php application/console newscoop:install --fix --database_name $dname --database_user $dname --database_password $dpw --database_override
    
    cd $HOME
    rm -rf public_html
    ln -s newscoop/newscoop public_html
    
    #finish
    echo_g "newscoop installed"
    echo_y "Just downloaded, go to site for manual install"
    echo_y "Install script does not asking you for administrator login. Is always 'admin'"
}

:<<=
==nodejs
===https://nodejs.org/
===https://github.com/nodejs/node/
=
function install_nodejs {
    #depencies
    echo_y "Satisfaying depencies..."
    install_nodejs_lts
}

:<<=
==nodejs 0.12
===https://nodejs.org/
===https://github.com/nodejs/node/
=
function install_nodejs012 {
    check_d
    echo_y "Installing nodejs 0.12..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk https://nodejs.org/dist/v0.12.7/node-v0.12.7.tar.gz > $HOME/.beget/tmp/node-v0.12.7.tar.gz
    if [ ! -f "$HOME/.beget/tmp/node-v0.12.7.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    cd $HOME/.beget/tmp
    tar xvf node-v0.12.7.tar.gz
    if [ ! -d "$HOME/.beget/tmp/node-v0.12.7" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    cd $HOME/.beget/tmp/node-v0.12.7
    ./configure --dest-os=linux --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ ! -f "$HOME/.local/bin/node" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #install
    echo_y "Setting up..."
    nodejs_npm

    #finish
    echo_g "Node.JS 0.12 installed"
}

:<<=
==nodejs (latest lts)
===https://nodejs.org/
===https://github.com/nodejs/node/
=
function install_nodejs_lts {
    echo_y "Installing Node.js LTS..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."

    url=`/usr/local/php-cgi/5.6/bin/php -r '$a=file_get_contents("https://nodejs.org/dist/index.json");$a=json_decode($a, true);foreach($a as $b){if($b["lts"]!=false){echo("https://nodejs.org/dist/latest-".strtolower($b["lts"])."/node-".$b["version"]."-linux-x64.tar.gz"); break;}}'`
    filename="${url##*/}"
    extracted_dir_name="${filename%.*.*}"

    cd $HOME/.beget/tmp
    curl -Lk $url > $HOME/.beget/tmp/$filename
    if [ ! -f "$HOME/.beget/tmp/$filename" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf $filename
    if [ ! -d "$HOME/.beget/tmp/$extracted_dir_name" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #install
    echo_y "Setting up..."
    mv $HOME/.beget/tmp/$extracted_dir_name $HOME/.local/opt/
    ln -sf $HOME/.local/opt/$extracted_dir_name/bin/node $HOME/.local/bin/node
    ln -sf $HOME/.local/opt/$extracted_dir_name/bin/npm $HOME/.local/bin/npm
    nodejs_npm

    #finish
    echo_g "Node.JS LTS installed"
}

function nodejs_npm {
    NPM_PACKAGES="$HOME/.local/npm-packages"
    mkdir -p "$NPM_PACKAGES"
    echo "prefix = $NPM_PACKAGES" > $HOME/.npmrc

    $HOME/.local/opt/$extracted_dir_name/lib/node_modules/npm/bin/npm-cli.js install npm@latest -g
    rm $HOME/.local/bin/npm
    ln -sf $HOME/.local/npm-packages/bin/npm $HOME/.local/bin/npm
    npm version
    npm install bower -g
    ln -sf $HOME/.local/npm-packages/bin/bower $HOME/.local/bin/bower
    bower --version
}

:<<=
==helloworld for Node.js
=
function install_nodejs_helloworld {
    check_ds
    echo_y "Installing Node.JS with hello-world..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_nodejs

    #install
    echo_y "Installing..."
    echo_y "Creating project..."
    cd $HOME

    mkdir -p $HOME/public
    rm -rf public_html
    ln -sf public public_html

    APPLICATION_PATH="$HOME/helloworld4nodejs/"
    mkdir $APPLICATION_PATH

    echo "PassengerNodejs $HOME/.local/bin/node
        PassengerAppRoot $APPLICATION_PATH
        PassengerAppType node
        PassengerStartupFile app.js" > $HOME/.htaccess

    echo "var http = require('http');
        var server = http.createServer(function(req, res) {
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end('Hello node.js!');
        });
        server.listen(3000);" > $APPLICATION_PATH/app.js

    mkdir -p $HOME/tmp
    touch $HOME/tmp/restart.txt

    #finish
    echo_g "hello-world installed"
}


:<<=
==Instant Client
===http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
=
function install_instant_client {
    check_ds
    echo_y "Installing Instant Client..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk http://download.oracle.com/otn/linux/instantclient/122010/instantclient-basic-linux.x64-12.2.0.1.0.zip?AuthParam=1496156495_25fb50b3ef12506a8cd3194cd54c9f38 > instantclient-basic-linux.x64-12.2.0.1.0.zip
    if [ ! -f "$HOME/.beget/tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    curl -Lk http://download.oracle.com/otn/linux/instantclient/122010/instantclient-sdk-linux.x64-12.2.0.1.0.zip?AuthParam=1496157472_8c27b44212baf43003c9647aa21c0b66 > instantclient-sdk-linux.x64-12.2.0.1.0.zip
    if [ ! -f "$HOME/.beget/tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip
    if [ ! -d "$HOME/.beget/tmp/instantclient_12_2" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    mv $HOME/.beget/tmp/instantclient_12_2 $HOME/.local/opt

    #finish
    echo_g "Instant Client installed"
}

:<<=
==oci8
===http://php.net/manual/ru/oci8.installation.php
===https://pecl.php.net/package/oci8/1.4.10
=
function install_oci8 {
    check_ds
    echo_y "Installing oci8..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_instant_client

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    #/usr/local/php-cgi/5.6/bin/pecl download oci8-1.4.10
    curl -Lk https://pecl.php.net/get/oci8-1.4.10.tgz > oci8-1.4.10.tgz
    if [ ! -f "$HOME/.beget/tmp/oci8-1.4.10.tgz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf oci8-1.4.10.tgz
    if [ ! -d "$HOME/.beget/tmp/oci8-1.4.10" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    PATH=$PATH:/usr/local/php-cgi/5.6/bin/
    ln -sf $HOME/.local/opt/instantclient_12_2/libclntsh.so.12.1 $HOME/.local/opt/instantclient_12_2/libclntsh.so
    
    cd $HOME/.beget/tmp/oci8-1.4.10
    phpize
    ./configure --prefix=$HOME/.local/lib/php/56/ -with-oci8=instantclient,$HOME/.local/opt/instantclient_12_2
    make install
    
    mkdir -p $HOME/.local/lib/php/56/
    cp modules/oci8.so $HOME/.local/lib/php/56/

    if [ ! -f $HOME/.local/lib/php/56/oci8.so ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #install
    echo_y "Installing..."
    if [ ! -f "$HOME/public_html/cgi-bin/php.ini" ]
    then
        mkdir -p $HOME/public_html/
        cp /etc/php/cgi/5.6/php.ini $HOME/public_html/cgi-bin/php.ini
    fi
    sed -i 's/; EOF//g' $HOME/public_html/cgi-bin/php.ini
    printf "\n\n[PHP]\nextension = $HOME/.local/lib/php/56/oci8.so" >> $HOME/public_html/cgi-bin/php.ini

    #finish
    echo_g "oci8 installed"
    echo_g "dont forget to switch to cgi"    
}


function install_optipng {
    check_d
    echo_y "Installing optipng..."
    prepare_folders
    cd $HOME/.beget/tmp

    echo_y "Downloading tarball"
    curl -Lk https://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-0.7.6/optipng-0.7.6.tar.gz > optipng-0.7.6.tar.gz
    if [ ! -f "$HOME/.beget/tmp/optipng-0.7.6.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    echo_y "Unpacking tarball"
    tar xvf optipng-0.7.6.tar.gz
    if [ ! -d "$HOME/.beget/tmp/optipng-0.7.6" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    echo_y "Compiling..."
    cd $HOME/.beget/tmp/optipng-0.7.6/
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install

    echo_g "optipng installed"
}


function install_pdfinfo {
    echo_y "Installing pdfinfo..."
    prepare_folders
    cd $HOME/.beget/tmp

    echo_y "Downloading tarball"
    wget ftp://ftp.foolabs.com/pub/xpdf/xpdfbin-linux-3.04.tar.gz -O $HOME/.beget/tmp/xpdfbin-linux-3.04.tar.gz
    if [ ! -f "$HOME/.beget/tmp/xpdfbin-linux-3.04.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    echo_y "Unpacking tarball"
    tar xvf xpdfbin-linux-3.04.tar.gz
    if [ ! -d "$HOME/.beget/tmp/xpdfbin-linux-3.04" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    mv $HOME/.beget/tmp/xpdfbin-linux-3.04 $HOME/.local/opt/
    for f in $HOME/.local/opt/xpdfbin-linux-3.04/bin64/*; do ln -sf $f $HOME/.local/bin/$(basename $f); done

    echo_g "pdfinfo installed"
}


:<<=
==phalcon
===NOT AN INSTALLER, JUST STUB TO CREATE INSTALLER
=
function install_phalcon {
    check_ds
    echo_y "Installing phalcon..."

    echo_y "Enter PHP version (default is 7.1)"
    read var
    if [[ ! $var ]]
    then
        var='7.1'
    fi

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."

    #cloning
    echo_y "Cloning..."
    cd $HOME/.beget/tmp
    git clone --depth=1 "git://github.com/phalcon/cphalcon.git"
    if [ ! -d "$HOME/.beget/tmp/cphalcon" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi
    

    #compilation
    echo_y "Compilating..."
    cd $HOME/.beget/tmp/cphalcon/build
    PATH=$PATH:/usr/local/php-cgi/$var/bin/
    ./install
    if [ ! -f "$HOME/.beget/tmp/cphalcon/build/php7/64bits/modules/phalcon.so" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #install
    echo_y "Installing..."
    mkdir -p "$HOME/.local/php/cgi/$var/lib/php/"
    cp "$HOME/.beget/tmp/cphalcon/build/php7/64bits/modules/phalcon.so" "$HOME/.local/php/cgi/$var/lib/php/"

    if [ ! -f "$HOME/public_html/cgi-bin/php.ini" ]
    then
        mkdir -p $HOME/public_html/cgi-bin/
        cp /etc/php/cgi/$var/php.ini $HOME/public_html/cgi-bin/php.ini
    fi
    sed -i 's/; EOF//g' $HOME/public_html/cgi-bin/php.ini
    printf "\n\n[PHP]\nextension = $HOME/.local/php/cgi/$var/lib/php/phalcon.so" >> $HOME/public_html/cgi-bin/php.ini

    echo '<?php phpinfo();' > $HOME/public_html/x.php

    #finish
    echo_g "phalcon installed"
}


:<<=
==PhantomJS
===PhantomJS is a headless WebKit scriptable with a JavaScript API.
===http://phantomjs.org/
=
function install_phantomjs {
    echo_y "Installing default..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders
    
    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 > phantomjs-2.1.1-linux-x86_64.tar.bz2
    if [ ! -f "$HOME/.beget/tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf phantomjs-2.1.1-linux-x86_64.tar.bz2
    if [ ! -d "$HOME/.beget/tmp/phantomjs-2.1.1-linux-x86_64" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    mv $HOME/.beget/tmp/phantomjs-2.1.1-linux-x86_64 $HOME/.local/opt/
    ln -sf $HOME/.local/opt/phantomjs-2.1.1-linux-x86_64/bin/phantomjs $HOME/.local/bin/phantomjs
    phantomjs -h

    #finish
    echo_g "PhantomJS installed"
}


function install_phpexpress {
    echo_y "Installing PhpExpress 3.1"
    prepare_folders
    cd $HOME/.beget/tmp
    
    curl -Lk http://download.nusphere.com/customer/download/files/NuSphere-PhpExpress-3.1.zip > $HOME/.beget/tmp/NuSphere-PhpExpress-3.1.zip
    if [ ! -f "$HOME/.beget/tmp/NuSphere-PhpExpress-3.1.zip" ]
    then
        echo_r 'download is failed'
        exit 1
    fi
    unzip NuSphere-PhpExpress-3.1.zip
    tar -xvf NuSphere-PhpExpress/phpexpress-3.1-Linux.tar.gz
    
    mkdir -p $HOME/.local/lib/php/53/
    cp $HOME/.beget/tmp/phpexpress-3.1-Linux/x86_64/phpexpress-php-5.3.so $HOME/.local/lib/php/53/phpexpress-php-5.3.so
    
    printf "\n\n[PHP]\nextension = $HOME/.local/lib/php/53/phpexpress-php-5.3.so" >> $HOME/public_html/cgi-bin/php.ini
    
    echo_g "PhpExpress installed"
    echo_y "Don't forget to switch php version to PHP 5.3 CGI!"
}

:<<=
==phpMyAdmin
===https://phpmyadmin.net/
=
function install_pma {
    check_ds
    echo_y "Installing phpMyAdmin..."

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer

    #install
    echo_y "Installing..."
    cd $HOME
    rm -rf public_html
    echo_y "Creating project..."
    composer -s stable create-project phpmyadmin/phpmyadmin public_html

    #finish
    echo_g "phpMyAdmin installed"
}

:<<=
==pngout
===https://ru.wikipedia.org/wiki/PNGOUT
===http://advsys.net/ken/utils.htm
===http://www.jonof.id.au/kenutils
=
function install_pngout {
    check_d
    echo_y "Installing pngout..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders
  
    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk http://static.jonof.id.au/dl/kenutils/pngout-20150319-linux-static.tar.gz > pngout-20150319-linux-static.tar.gz
    if [ ! -f "$HOME/.beget/tmp/pngout-20150319-linux-static.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar -xvf pngout-20150319-linux-static.tar.gz
    if [ ! -d "$HOME/.beget/tmp/pngout-20150319-linux-static" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    mv pngout-20150319-linux-static $HOME/.local/opt/
    ln $HOME/.local/opt/pngout-20150319-linux-static/x86_64/pngout-static $HOME/.local/bin/pngout

    #finish
    echo_g "pngout installed"
}


function install_pngquant {
    echo_y "Installing pngquant..."

    #prepare folders
    prepare_folders
    rm -rf $HOME/.beget/tmp/pngquant
    cd $HOME/.beget/tmp

    #download
    echo_y "Cloning repo"
    git clone https://github.com/pornel/pngquant.git
    if [ ! -d "$HOME/.beget/tmp/pngquant" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi

    #compile
    echo_y "Compiling..."
    cd $HOME/.beget/tmp/pngquant
    ./configure --prefix=$HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ -f "$HOME/.local/bin/pngquant" ]
    then
        echo_g "pngquant installed"
    else
        echo_r "Seems like compilation is failed"
        exit 1
    fi
}


:<<=
==PrestaShop
===https://www.prestashop.com
===https://github.com/PrestaShop/PrestaShop
=
function install_prestashop {
    check_ds
    echo_y "Installing PrestaShop..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer

    #download
    echo_y "Cloning..."
    cd $HOME
    git clone https://github.com/PrestaShop/PrestaShop.git
    if [ ! -d "$HOME/PrestaShop" ]
    then
        echo_r "Seems like cloning is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    
    mkdir $HOME/.local/etc
    printf "[PHP]\ndate.timezone = Europe/Moscow\nshort_open_tag = On" > $HOME/.local/etc/php.ini
    echo "/usr/local/php-cgi/5.6/bin/php -c $HOME/.local/etc/php.ini \$@" > $HOME/.local/bin/php
    chmod +x $HOME/.local/bin/php
    
    rm -rf public_html
    mv PrestaShop public_html
    cd public_html
    composer install

    #finish
    echo_g "PrestaShop installed"
}


function install_python3 {
    echo_y 'Installing Python 3'
    check_d

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #Download
    echo_y 'Downloading...'
    curl -Lk https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tgz > $HOME/.beget/tmp/Python-3.6.3.tgz
    if [ ! -f "$HOME/.beget/tmp/Python-3.6.3.tgz" ]
    then
        echo_r 'download is failed'
        exit 1
    fi

    #Unpacking
    cd $HOME/.beget/tmp
    echo_y 'Unpacking...'
    tar xvf Python-3.6.3.tgz
    if [ ! -d "$HOME/.beget/tmp/Python-3.6.3" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #Compiling
    echo_y "Compiling..."
    cd Python-3.6.3
    ./configure --prefix $HOME/.local
    make -j $(expr $(nproc) / 21)
    make install
    if [ ! -f "$HOME/.local/bin/pip3" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    pip3 install --upgrade pip

    #finish
    echo_g "Python 3 installed"
}


:<<=
==Ruby On Rails
=
function install_ror {
    check_ds
    echo_y "Installing Ruby On Rails..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_nodejs

    #install
    echo_y "Installing..."
    chruby ruby-2.3
    echo '2.3' > $HOME/.ruby-version
    cd $HOME
    gem install rails --no-rdoc --no-ri
    gem install rb-readline --no-rdoc --no-ri
    rails new .
    ln -sf public public_html
    echo "gem 'rb-readline'
gem 'execjs'
gem 'therubyracer'" >> $HOME/Gemfile
    bundle install

    echo_y "Setting up..."
    echo "RailsEnv development
PassengerUploadBufferDir `pwd`/tmp
PassengerRuby /opt/rubies/ruby-2.3/bin/ruby
PassengerAppRoot `pwd`
SetEnv GEM_HOME $HOME/.gem/ruby/2.3.1/:/opt/rubies/ruby-2.3/lib/ruby/gems/2.3.0/" >> $HOME/.htaccess
    echo "ENV['GEM_HOME'] = '$HOME/.gem/ruby/2.3.1/'
ENV['GEM_PATH'] = '$HOME/.gem/ruby/2.3.1/'
require 'bundler/setup'" >> $HOME/config/setup_load_paths.rb
    mkdir $HOME/tmp
    touch $HOME/tmp/restart.txt

    main_acc=$(ruby -e 'print `whoami`.gsub(/__[a-z0-9_]+$/, "")')
    echo "ssh $main_acc@localhost -p 222 /opt/rubies/2.3/bin/ruby \$@" > ~/.local/bin/ruby
    chmod +x ~/.local/bin/ruby
    ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$main_acc@localhost -p 222"

    #finish
    echo_g "Ruby On Rails installed"
}


:<<=
==unixodbc
===http://www.unixodbc.org/
=
function install_unixodbc {
    check_d
    echo_y "Installing unixODBC..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #download
    echo_y "Downloading..."
    cd $HOME/.beget/tmp
    curl -Lk http://www.unixodbc.org/unixODBC-2.3.4.tar.gz > unixODBC-2.3.4.tar.gz
    if [ ! -f "$HOME/.beget/tmp/unixODBC-2.3.4.tar.gz" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #unpack
    echo_y "Unpacking..."
    tar xvf unixODBC-2.3.4.tar.gz
    if [ ! -d "$HOME/.beget/tmp/unixODBC-2.3.4" ]
    then
        echo_r "Seems like unpacking is failed"
        exit 1
    fi

    #compilation
    echo_y "Compilating..."
    cd unixODBC-2.3.4
    mkdir $HOME/.local/etc
    ./configure --prefix=$HOME/.local --sysconfdir=$HOME/etc
    make -j $(expr $(nproc) / 21)
    make install
    if [ ! -f "$HOME/.local/bin/odbc_config" ]
    then
        echo_r 'seems like compilation is failed'
        exit 1
    fi

    #finish
    echo_g "unixODBC installed"
}


:<<=
==WP CLI
===http://wp-cli.org/
=
function install_wpcli {
    echo_y "Installing WP CLI..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer
    
    #download
    echo_y "Downloading..."
    mkdir $HOME/.local/opt/wpcli/
    cd $HOME/.local/opt/wpcli/
    curl -Lk https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > wp-cli.phar
    curl -Lk https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash > wp-completion.bash
    if [ ! -f "$HOME/.local/opt/wpcli/wp-cli.phar" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi
    if [ ! -f "$HOME/.local/opt/wpcli/wp-completion.bash" ]
    then
        echo_r "Seems like downloading is failed"
        exit 1
    fi

    #install
    echo_y "Installing..."
    echo "/usr/local/php-cgi/5.6/bin/php $HOME/.local/opt/wpcli/wp-cli.phar \$@" > $HOME/.local/bin/wp
    chmod +x $HOME/.local/bin/wp
    printf "\n\nsource $HOME/.local/opt/wpcli/wp-completion.bash" >> $HOME/.bash_profile

    #finish
    echo_g "WP CLI installed"
}

:<<=
==Wordpress
=
function install_wordpress {
    check_ds
    echo_y "Installing wordpress..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_wpcli
  
    #download
    echo_y "Downloading..."

    wp_dl_cmd='wp core download --path=. '

    echo "ENTER WORDPRESS LANGUAGE (default is ru_RU)"
    read wp_localization
    if [[ $wp_localization ]]
    then
        wp_dl_cmd="$wp_dl_cmd --locale=$wp_localization"
    else
        wp_dl_cmd="$wp_dl_cmd --locale=ru_RU"
    fi

    echo "ENTER WORDPRESS VERSION (default is latest)"
    read wp_version
    if [[ $wp_version ]]
    then
        wp_dl_cmd="$wp_dl_cmd --version=$wp_version"
    fi

    wp_dl_cmd="$wp_dl_cmd --force"

    cd $HOME/public_html
    eval $wp_dl_cmd

    #install
    echo_y "Setting up database..."
    echo "ENTER HOSTING ACCOUNT LOGIN"
    read account
    export account

    echo "ENTER HOSTING ACCOUNT PASSWORD"
    read password
    export password

    db_suffix=`/usr/local/php-cgi/5.6/bin/php -r '$p="";for($l=0;$l<5;$l++) {$p.=chr(rand(97,122));}echo $p;'` #there is no pwgen in docker
    export db_suffix

    db_password=`/usr/local/php-cgi/5.6/bin/php -r '$p="";for($l=0;$l<8;$l++) {$p.=chr(rand(97,122));}echo $p;'`
    export db_password

    admin_password=`/usr/local/php-cgi/5.6/bin/php -r '$p="";for($l=0;$l<8;$l++) {$p.=chr(rand(97,122));}echo $p;'`

    mkdb_url=`/usr/local/php-cgi/5.6/bin/php -r '$url="https://api.beget.ru/api/mysql/addDb?";

    $a=[];
    $a["login"]=getenv("account");
    $a["passwd"]=getenv("password");
    #$a["input_format"]="json";
    $a["input_format"]="json";
    $a["input_data"]=json_encode(["suffix"=>getenv("db_suffix"),"password"=>getenv("db_password")]);

    $url.=http_build_query($a);

    echo($url);'`


    curl -Lk $mkdb_url
    echo ''
    sleep 5 #database is not creating immediatelly, need to wait some seconds
    echo "wp core config --dbname=${account}_${db_suffix} --dbuser=${account}_${db_suffix} --dbpass=${db_password} --dbhost=localhost --dbcharset=utf8 --dbcollate=utf8_general_ci"

    wp core config --dbname=${account}_${db_suffix} --dbuser=${account}_${db_suffix} --dbpass=${db_password} --dbhost=localhost --dbcharset=utf8 --dbcollate=utf8_general_ci

    echo_y "Setting up wp..."
    echo "ENTER SITE URL"
    read siteurl
    export siteurl

    echo "ENTER ADMIN EMAIL"
    read admin_email
    export admin_email

    wp core install --url=${siteurl} --title='' --admin_user=${account} --admin_password=${admin_password} --admin_email=${admin_email}

    echo "${siteurl}/wp-login.php"
    echo $account
    echo $admin_password



    #finish
    echo_g "WordPress installed"
}


:<<=
==Yii
===http://www.yiiframework.com/
=
function install_yii {
    check_ds
    echo_y "Installing Yii..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #depencies
    echo_y "Satisfaying depencies..."
    install_composer
    install_nodejs

    #install
    echo_y "Installing..."
    cd ~
    composer global require "fxp/composer-asset-plugin:^1.2.0"
    echo_y "Creating project..."
    rm -rf _yii_tmp
    composer create-project -s stable yiisoft/yii2-app-basic _yii_tmp
    shopt -s dotglob
    mv _yii_tmp/* .   
    rm -rf _yii_tmp 

    rm -rf public_html
    ln -s web public_html

    #finish
    echo_g "Yii installed"
}


case $1 in
    -h|--help)
        installer_help
        ;;
    'apt')
        apt_localinstall $2
        ;;
    'composer')
        install_composer
        ;;
    cwebp|dwebp)
        install_cwebp
        ;;
    'django')
        install_django
        ;;
    'drupal8')
        install_drupal_8
        ;;
    'drupalconsole')
        install_drupalconsole
        ;;
    'drush')
        install_drush $2
        ;;
    'ewww')
        install_ewww
        ;;
    'flask')
        install_flask
        ;;
    'ghostscript')
        install_ghostscript
        ;;
    'gifsicle')
        install_gifsicle
        ;;
    'git')
        install_git
        ;;
    'gmagick')
        install_gmagick
        ;;
    'htop')
        install_htop
        ;;
    'jpegoptim')
        install_jpegoptim
        ;;
    'jpegtran')
        install_jpegtran
        ;;
    'haskell')
        install_haskell
        ;;
    'joomlatools')
        install_joomlatools
        ;;
    'laravel')
        install_laravel
        ;;
    'magento_ce')
        install_magento_ce
        ;;
    'magento_ee')
        install_magento_ee
        ;;
    'ncdu')
        install_ncdu
        ;;
    'newscoop')
        install_newscoop
        ;;
    'nodejs')
        install_nodejs
        ;;
    'nodejs_hw')
        install_nodejs_helloworld
        ;;
    'opencart')
            install_opencart
            ;;
    'optipng')
        install_optipng
        ;;
    'pdfinfo')
        install_pdfinfo
        ;;
    'pngout')
        install_pngout
        ;;
    'phalcon')
        install_phalcon
        ;;
    'phantomjs')
        install_phantomjs
        ;;
    'phpexpress')
        install_phpexpress
        ;;
    'pngquant')
        install_pngquant
        ;;
    'pma')
        install_pma
        ;;
    'prestashop')
        install_prestashop
        ;;
    'python3')
        install_python3
        ;;
    'siege')
        install_siege
        ;;
    'ror')
        install_ror
        ;;
    'wordpress')
        install_wordpress
        ;;
    'wpcli')
        install_wpcli
        ;;
    'yii')
        install_yii
        ;;
    *)
        echo 'Unknown parameter'
esac

#TODO
#wget http://www.1c-bitrix.ru/download/scripts/bitrixsetup.php
#wget http://www.hostcms.ru/download/install/install.php
