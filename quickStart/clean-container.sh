#!/bin/bash
# first parameter is the name of the new container
CONTAINER_NAME=$1

echo 'clean the container $CONTAINER_NAME'
docker stop $CONTAINER_NAME 
docker rm -f $CONTAINER_NAME 
docker volume rm TOMCAT_FOLDER_ROOT