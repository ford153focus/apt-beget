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
