#!/bin/bash

echo "user for path creation is : $USER"
VERSION=9
NETWORK_NAME=odevarc.net
IMAGE_NAME=tomcat:9

# first parameter is the name of the new container
CONTAINER_NAME=$1
# second parameter is port like 80
EXTERNAL_PORT=$2
# third parameter us do we create a folder on host
# =true or not =false
CREATE_FOLDER_MAPPING=$3

echo '¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤  START  ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤'
echo -e "\n\tScript parameters are : $@\n"
echo -e "\tCONTAINER_NAME is $CONTAINER_NAME"
echo -e "\tEXTERNAL_PORT for Tomcat port is $EXTERNAL_PORT"
echo -e "\tCREATE_FOLDER_MAPPING is $CREATE_FOLDER_MAPPING"
echo ''

# create folder if needed
if [ "$CREATE_FOLDER_MAPPING" == true ]; then
    echo -e '\tDefining folder path to put volumes folders which ones MUST not exist otherwise container content will be replaced by local host folder content'
    TOMCAT_FOLDER_ROOT=$HOME/docker-prod/volumes/tomcat-$VERSION/directories/$CONTAINER_NAME_${EXTERNAL_PORT}
    echo ''
fi

echo ''
echo -e '\tCreate the network $NETWORK_NAME inly if it does not exist'
if ! docker network ls | grep -q esrifrance.net; then
	echo ''
    echo -e '\tCreate specific network to allow all containers to communicate :\n\n'
	docker network create $NETWORK_NAME
    echo ''
fi

echo ''
echo -e "\tSubnet for new network $NETWORK_NAME is : " 
echo -e "\t$(docker network inspect $NETWORK_NAME --format '{{(index .IPAM.Config 0).Subnet }}')"
echo ''

if [ "$CREATE_FOLDER_MAPPING" == true ]; then
    echo ''
    echo -e "\tCreate the new container $CONTAINER_NAME from the image with binding in folder $TOMCAT_FOLDER_ROOT"
    docker container run --name $CONTAINER_NAME --hostname "$CONTAINER_NAME.$NETWORK_NAME"  --restart=always -p ${EXTERNAL_PORT}:8080 -d --mount 'type=volume,src=TOMCAT_FOLDER_ROOT,dst=/usr/local/tomcat' $IMAGE_NAME
    #docker container run --name $CONTAINER_NAME --hostname "$CONTAINER_NAME.$NETWORK_NAME"  --restart=always -p ${EXTERNAL_PORT}:8080 -d -v $TOMCAT_FOLDER_ROOT:/usr/local/tomcat/logs $IMAGE_NAME
    echo -e "Local path is cd $PWD"
else
    echo ''
    echo -e "\tCreate the new container $CONTAINER_NAME from the image without host folder binding"
    docker container run --name $CONTAINER_NAME --hostname "$CONTAINER_NAME.$NETWORK_NAME" --restart=always -p ${EXTERNAL_PORT}:8080 -d $IMAGE_NAME
fi
echo ''

echo ''
echo -e '\tWaiting 20 seconds until Tomcat is starting ...'
sleep 20
echo ''

# DEBUG to see processes 
#docker exec -t $CONTAINER_NAME /bin/bash -c "ps -aux"

echo ''
echo -e "\tCheck that Tomcat is UP AND RUNING \n\n"
docker exec -t $CONTAINER_NAME /bin/bash -c "curl http://$CONTAINER_NAME.$NETWORK_NAME:8080/ --head"
echo ''

echo ''
echo -e "\tCopy config files for the java tomcat servlet filter accessLogGetPOSTQueryString\n\n"
docker cp arcgis.xml $CONTAINER_NAME:/usr/local/tomcat/conf/Catalina/localhost/arcgis.xml

echo -e "\tCreate a FAKE webapps named 'arcgis' (in real world this is the Esri webapdator\n"
docker exec -t $CONTAINER_NAME /bin/bash -c "mkdir /usr/local/tomcat/webapps/arcgis"
docker exec -t $CONTAINER_NAME /bin/bash -c "cp /usr/local/tomcat/webapps/ROOT/index.html /usr/local/tomcat/webapps/arcgis/index.html"

echo -e "\tVerify files deployed"
docker exec -t $CONTAINER_NAME /bin/bash -c "tree /usr/local/tomcat/conf"
docker exec -t $CONTAINER_NAME /bin/bash -c "tree /usr/local/tomcat/filter"
docker exec -t $CONTAINER_NAME /bin/bash -c "tree /usr/local/tomcat/webapps"



echo 'Updating server.xml file'
docker exec -t $CONTAINER_NAME /bin/bash -c 'sed -i "s/<Valve className=\"org.apache.catalina.valves.AccessLogValve\" directory=\"logs\"//g" /usr/local/tomcat/conf/server.xml'
docker exec -t $CONTAINER_NAME /bin/bash -c 'sed -i "s/prefix=\"localhost_access_log\" suffix=\".txt\"//g" /usr/local/tomcat/conf/server.xml'
docker exec -t $CONTAINER_NAME /bin/bash -c 'sed -i "s/pattern=\"%h %l %u %t &quot;%r&quot; %s %b\" \/>/NEW_ACCESSLOG_CONFIG/g" /usr/local/tomcat/conf/server.xml'


# be aware to NOT put tabs or spaces on the begining of lines in the multiline section """ 
# be aware to NOT put space AFTER end of doc EOF
cat <<EOF > update_docker_container_tomcat_server_xml_file.py
import os, sys 
fname = 'server.xml'
os.rename(fname, fname + '.orig')
with open(fname + '.orig', 'rt') as fin, open(fname, 'wt') as fout:
    #for each line in the input file
    for line in fin:
        #read replace the string and write to output file
        fout.write(line.replace(
        'NEW_ACCESSLOG_CONFIG'
        ,"""
\t<!-- Logs customized by oDevArc ! https://tomcat.apache.org/tomcat-9.0-doc/config/valve.html#Access_Logging -->
\t<!--     %a - Remote IP address
\t%A - Local IP address
\t%b - Bytes sent, excluding HTTP headers, or '-' if zero
\t%B - Bytes sent, excluding HTTP headers
\t%h - Remote host name (or IP address if enableLookups for the connector is false)
\t%H - Request protocol
\t%l - Remote logical username from identd (always returns '-')
\t%m - Request method (GET, POST, etc.)
\t%p - Local port on which this request was received. See also %{xxx}p below.
\t%q - Query string (prepended with a '?' if it exists)
\t%r - First line of the request (method and request URI)
\t%s - HTTP status code of the response
\t%S - User session ID
\t%t - Date and time, in Common Log Format
\t%u - Remote user that was authenticated (if any), else '-'
\t%U - Requested URL path
\t%v - Local server name
\t%D - Time taken to process the request, in millis
\t%T - Time taken to process the request, in seconds
\t%F - Time taken to commit the response, in millis
\t%I - Current request thread name (can compare later with stacktraces)
\t%X - Connection status when response is completed:
\t+ = Connection may be kept alive after the response is sent.
\t- = Connection will be closed after the response is sent.

\tThere is also support to write information incoming or outgoing headers, cookies, session or request attributes and special timestamp formats. It is modeled after the Apache HTTP Server log configuration syntax. Each of them can be used multiple times with different xxx keys:
\t%{xxx}i write value of incoming header with name xxx
\t%{xxx}o write value of outgoing header with name xxx
\t%{xxx}c write value of cookie with name xxx
\t%{xxx}r write value of ServletRequest attribute with name xxx
\t%{xxx}s write value of HttpSession attribute with name xxx
\t%{xxx}p write local (server) port (xxx==local) or remote (client) port (xxx=remote)
\t%{xxx}t write timestamp at the end of the request formatted using the enhanced SimpleDateFormat pattern xxx
\t-->

\t<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" fileDateFormat="_yyyyMMdd" pattern="%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%{request_parameters}r" prefix="_accesslog_withGetPOSTQueryString" renameOnRotate="true" resolveHosts="false" suffix=".log" encoding="UTF-8"/>

\t<!-- 
\tOTHER pattern examples :
\tpattern="${hostname}::%a::%{X-Forwarded-For}i::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%r::%{User-Agent}i::%{Referer}i::%b::%D::%{request_parameters}r"
\tpattern="${hostname}::%a::%{X-Forwarded-For}i::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{User-Agent}i::%{Referer}i::%b::%D::%{request_parameters}r"
\tpattern="CuTe::%a::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{Referer}i::%q::%{User-Agent}i::%b::%D::%{agstoken}c::%{request_parameters}r"
\tpattern="%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{request_parameters}r"
\tpattern="${hostname}::%a::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%r::%U::%{User-Agent}i::%b::%D::%{request_parameters}r"
\t-->
        """ 
        )
        )
EOF

echo ''
echo -e '\tPut the python script to update the server.xml file container :\n'
docker cp update_docker_container_tomcat_server_xml_file.py $CONTAINER_NAME:/usr/local/tomcat/conf/update_docker_container_tomcat_server_xml_file.py
#docker exec -t $CONTAINER_NAME /bin/bash -c "cat /usr/local/tomcat/conf/server.xml"
docker exec -t $CONTAINER_NAME /bin/bash -c "cd /usr/local/tomcat/conf/; python update_docker_container_tomcat_server_xml_file.py"
#docker exec -t $CONTAINER_NAME /bin/bash -c "cat /usr/local/tomcat/conf/server.xml"
echo ''
echo -e '\tRestart Tomcat to activate GET/POST parameters tracing in access logs :\n'
docker exec -t $CONTAINER_NAME /bin/bash -c "/usr/local/tomcat/bin/shutdown.sh"
docker exec -t $CONTAINER_NAME /bin/bash -c "/usr/local/tomcat/bin/startup.sh"

sleep 10

echo ''
echo -e '\tShow the new access log after a GET request with parameters :\n'
curl 'http://localhost/arcgis/rest/services/SampleWorldCities/MapServer/0/query?where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=json' -H 'User-Agent: cURL' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.8,fr;q=0.5,fr-FR;q=0.3' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache'  -s > /dev/null
sleep 10
docker exec -t $CONTAINER_NAME /bin/bash -c "tail /usr/local/tomcat/logs/_accesslog_withGetPOSTQueryString.log"

echo ''
echo -e '\tShow the new access log after a POST request with parameters :\n'
curl 'http://localhost/arcgis/rest/services/SampleWorldCities/MapServer/0/query' -H 'User-Agent: cURL' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data 'where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnjsoninctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=json' -s > /dev/null
sleep 10
docker exec -t $CONTAINER_NAME /bin/bash -c "tail /usr/local/tomcat/logs/_accesslog_withGetPOSTQueryString.log"


echo ''
echo -e '\tShow the state of docker container :\n'
docker ps --filter name=$CONTAINER_NAME --format "Container {{.Names}} [{{.ID}}] sur image {{.Image}}" 
docker ps --filter name=$CONTAINER_NAME --format " on ports : {{.Ports}} | taille  {{.Size}}" 
docker ps --filter name=$CONTAINER_NAME --format " with size :  {{.Size}}" 
echo ''

echo ''
echo -e '\tYou may access to internal container system via the next command :'
echo -e "\tdocker exec -it $CONTAINER_NAME  /bin/bash"
# DEBUG : open the container 
#docker exec -it $CONTAINER_NAME  /bin/bash




echo '¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤  END  ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤'
