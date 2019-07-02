#!/bin/bash

folder=$1

if [[ -n "$folder" ]]; then
    unzip -n -q $folder/prestashop.zip -d $folder/prestashop
    rm -rf $folder/prestashop.zip
    chown www-data:www-data -R $folder/prestashop/
    cp -n -R -p $folder/prestashop/* /var/www/html
else
    echo "Missing folder to move"
fi