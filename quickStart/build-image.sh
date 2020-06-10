#!/bin/bash
docker build --tag tomcat:9 --rm=true . --ulimit nofile=262144:262144 --ulimit nproc=25059:25059