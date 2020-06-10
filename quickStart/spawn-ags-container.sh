#!/bin/bash
CONTAINER_NAME=testTomcat9
./clean-container.sh $CONTAINER_NAME
# name / host port (ie 80) / map the Tomcat CATALINA_HOME directory to the host folder 
./run-container.sh $CONTAINER_NAME 80 true
