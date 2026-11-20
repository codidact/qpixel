#!/bin/bash

mysqld --init-file=/docker-entrypoint-initdb.d/mysql-init.sql \
       --mysql-native-password=on \
       --skip-mysqlx
