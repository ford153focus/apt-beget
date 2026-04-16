#!/usr/bin/env bash
:<<=
==Symfony 8
=
function install_symfony8 {
    shopt -s dotglob
    cd "$HOME" || exit
    rm -rf ./*

    # set default php version
    mkdir -p "$HOME/.local/bin"
    echo '/usr/local/bin/php8.4 $@'  > ~/.local/bin/php
    chmod +x ~/.local/bin/php

    # get fresh composer
    curl -Lk 'https://getcomposer.org/installer' > ~/composer-setup.php
    php ~/composer-setup.php
    rm ~/composer-setup.php
    mv composer.phar ~/.local/bin/composer
    chmod +x ~/.local/bin/composer

    composer create-project symfony/skeleton:"8.0.*" tmp

    mv tmp/* .
    rm -rf tmp/
    ln -s public public_html

    composer require webapp
    composer require symfony/apache-pack

    # get symfony cli
    curl -sS https://get.symfony.com/cli/installer | bash
    mv "$HOME/.symfony5/bin/symfony" "$HOME/.local/bin/symfony"
    rm -rf "$HOME/.symfony5/"
}
