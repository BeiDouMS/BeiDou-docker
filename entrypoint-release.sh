#!/bin/sh

working_dir=/opt/server

working_dir_bak=/opt/server_backup
 
mkdir -p $working_dir

if [ -z "$(ls -A $working_dir)" ]; then
    echo "first run container , cp files from backup."
    cp -r $working_dir_bak/* $working_dir
fi

rm -rf $working_dir_bak

cd $working_dir && ./jdk-21.0.2/bin/java ${JAVA_OPTS} -jar ./BeiDou.jar --spring.config.location=./application.yml $@
