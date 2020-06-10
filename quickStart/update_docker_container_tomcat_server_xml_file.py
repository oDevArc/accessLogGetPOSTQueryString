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
\tpattern="::%a::%{X-Forwarded-For}i::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%r::%{User-Agent}i::%{Referer}i::%b::%D::%{request_parameters}r"
\tpattern="::%a::%{X-Forwarded-For}i::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{User-Agent}i::%{Referer}i::%b::%D::%{request_parameters}r"
\tpattern="CuTe::%a::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{Referer}i::%q::%{User-Agent}i::%b::%D::%{agstoken}c::%{request_parameters}r"
\tpattern="%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%U::%{request_parameters}r"
\tpattern="::%a::%m::%s::%{yyyy-MM-dd HH:mm:ss}t::%r::%U::%{User-Agent}i::%b::%D::%{request_parameters}r"
\t-->
        """ 
        )
        )
