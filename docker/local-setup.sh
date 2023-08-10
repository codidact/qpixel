#!/bin/bash

cp ./docker/dummy.env ./docker/env
cp ./docker/compose-env .env
cp config/database.docker.yml config/database.yml
cp config/storage.docker.yml config/storage.yml
cp ./.irbrc.sample ./.irbrc