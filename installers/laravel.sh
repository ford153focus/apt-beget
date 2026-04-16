#!/usr/bin/env bash
:<<=
==Laravel
=
function install_laravel {
    check_ds
    echo_y "Installing Laravel..."

    #prepare folders
    echo_y "Preparing folders..."
    prepare_folders

    #install
    echo_y "Installing..."
    cd ~ || exit
    rm -rf ~/public_html
    mkdir -p ~/.local/bin
    mkdir -p ~/.local/etc

    echo "/usr/local/php-cgi/7.2/bin/php \$@" > $HOME/.local/bin/php
    echo "/usr/local/bin/composer-php7.2 \$@" > $HOME/.local/bin/composer
    chmod +x $HOME/.local/bin/*
    
    composer create-project --prefer-dist laravel/laravel ~/tmp
    shopt -s dotglob
    mv ~/tmp/* .
    
    ln -s public public_html
    chmod +x ~/artisan
    ./artisan key:generate
    ./artisan config:clear

    #finish
    echo_g "Laravel installed"
}
