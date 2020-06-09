# accessLogGetPOSTQueryString


## summary

This simple java tomcat servlet filter is designed to allow write to standard access log parameters from GET and POST requests.

This projet was first designed to catch requests sent to ESRI ArcGIS Server /arcgis/ WebAdaptor (which is a simple Tomcat webapp) to inject them to No SQL database (Elastic Stack including Logstash > ElasticSearch / Kibana) 

## QuickStart 

You have all resources to deploy on Tomcat 9 : 

**All files are in [./quickStart/](./quickStart/) folder**

1) first we need to declare the servlet filter for our webapp (in this case Esri ArcGIS Server) : `/opt/tomcat/conf/Catalina/localhost/arcgis.xml` 

the content of the file is : 

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!-- The contents of this file will be loaded for arcgis webadaptor -->
<Context>
<Resources className="org.apache.catalina.webresources.StandardRoot">    
        <PreResources className="org.apache.catalina.webresources.DirResourceSet"
            base="/opt/tomcat/filter/lib"
            webAppMount="/WEB-INF/lib" />

<PreResources className="org.apache.catalina.webresources.DirResourceSet"
            base="/opt/tomcat/filter/conf_arcgis"
            webAppMount="/WEB-INF/classes" />
    </Resources>
</Context>
```
2) note that you must update the Tomcat launch script : `/opt/tomcat/bin/catalina.sh` update near the line `251` you can set the HOSTNAME variable AND the DEBUG parameters (port 8081) for Eclipse debugging : 

```
# -----------------------------------------------------------------------------------------------
# hostname variable used by access logging with filter to get POST & GET parameters /accessLogGetPOSTQueryString
JAVA_OPTS="$JAVA_OPTS -Dhostname=CuTe"
# DEBUG dans eclipse
JAVA_OPTS="$JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8081"
# -----------------------------------------------------------------------------------------------
```


3) update the file `/opt/tomcat/server.xml`add at the end just after `<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" prefix="localhost_access_log" suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
    -->` :

```xml
<!-- Logs customized by oDevArc ! https://tomcat.apache.org/tomcat-9.0-doc/config/valve.html#Access_Logging -->

<!--     %a - Remote IP address
%A - Local IP address
%b - Bytes sent, excluding HTTP headers, or '-' if zero
%B - Bytes sent, excluding HTTP headers
%h - Remote host name (or IP address if enableLookups for the connector is false)
%H - Request protocol
%l - Remote logical username from identd (always returns '-')
%m - Request method (GET, POST, etc.)
%p - Local port on which this request was received. See also %{xxx}p below.
%q - Query string (prepended with a '?' if it exists)
%r - First line of the request (method and request URI)
%s - HTTP status code of the response
%S - User session ID
%t - Date and time, in Common Log Format
%u - Remote user that was authenticated (if any), else '-'
%U - Requested URL path
%v - Local server name
%D - Time taken to process the request, in millis
%T - Time taken to process the request, in seconds
%F - Time taken to commit the response, in millis
%I - Current request thread name (can compare later with stacktraces)
%X - Connection status when response is completed:
X = Connection aborted before the response completed.
+ = Connection may be kept alive after the response is sent.
- = Connection will be closed after the response is sent.

There is also support to write information incoming or outgoing headers, cookies, session or request attributes and special timestamp formats. It is modeled after the Apache HTTP Server log configuration syntax. Each of them can be used multiple times with different xxx keys:
%{xxx}i write value of incoming header with name xxx
%{xxx}o write value of outgoing header with name xxx
%{xxx}c write value of cookie with name xxx
%{xxx}r write value of ServletRequest attribute with name xxx
%{xxx}s write value of HttpSession attribute with name xxx
%{xxx}p write local (server) port (xxx==local) or remote (client) port (xxx=remote)
%{xxx}t write timestamp at the end of the request formatted using the enhanced SimpleDateFormat pattern xxx
-->

<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" fileDateFormat="_yyyyMMdd" pattern="%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%{request_parameters}r" prefix="${hostname}_accesslog" renameOnRotate="true" resolveHosts="false" suffix=".log" encoding="UTF-8"/>

<!-- 
OTHER pattern examples :
pattern="${hostname}::%a::%{X-Forwarded-For}i::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%r::%{User-Agent}i::%{Referer}i::%b::%D::%{request_parameters}r"
pattern="${hostname}::%a::%{X-Forwarded-For}i::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{User-Agent}i::%{Referer}i::%b::%D::%{request_parameters}r"
pattern="CuTe::%a::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{Referer}i::%q::%{User-Agent}i::%b::%D::%{agstoken}c::%{request_parameters}r"
pattern="%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{request_parameters}r"
pattern="${hostname}::%a::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%r::%U::%{User-Agent}i::%b::%D::%{request_parameters}r"
-->

```

4) put all the jar files into the folder `/opt/tomcat/filter/lib` including the servlet filter `accessLogGetPOSTQueryString.jar`

5) define the logger defining file `/opt/tomcat/filter/conf_arcgis/log4j2.xml` designed for getting servlet message themself (not the POST/GET parameters tracing) ; content is like this :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="INFO">
    <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n" />
        </Console>
        <File name="filter" fileName="/opt/tomcat/logs/filter_arcgis.log" immediateFlush="true" append="false">
            <PatternLayout pattern="%d{yyy-MM-dd HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </File>
    </Appenders>
    <Loggers>
        <Root level="debug">
            <AppenderRef ref="Console" level="info"/>
            <AppenderRef ref="filter"/>
        </Root>
    </Loggers>
</Configuration>
```

After all these actions you must restart your Tomcat by calling `systemctl restart tomcat.service` and some requests send by `curl` like these : 

- GET : 

```bash
curl 'https://cute.arcgis.net/arcgis/rest/services/SampleWorldCities/MapServer/0/query?where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=json' -H 'User-Agent: cURL' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.8,fr;q=0.5,fr-FR;q=0.3' --compressed -H 'Connection: keep-alive' -H 'Referer: https://cute.esrifrance.net/arcgis/rest/services/SampleWorldCities/MapServer/0/query' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache'
```

- POST :

```bash
curl 'https://cute.arcgis.net/arcgis/rest/services/SampleWorldCities/MapServer/0/query' -H 'User-Agent: cURL' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.8,fr;q=0.5,fr-FR;q=0.3' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://cute.esrifrance.net' -H 'Connection: keep-alive' -H 'Referer: https://cute.esrifrance.net/arcgis/rest/services/SampleWorldCities/MapServer/0/query?where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=html' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data 'where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnjsoninctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=json'
```

will produce in `/opt/tomcat/logs/CuTe_accesslog.log` file this type of lines :

```
GET::500::2020-06-05 18:30:10::?where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=json

POST::500::2020-06-05 18:30:33::?where=CITY_NAME%3D%27Cuiaba%27&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&having=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnjsoninctValues=false&resultOffset=&resultRecordCount=&queryByDistance=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=json
```

