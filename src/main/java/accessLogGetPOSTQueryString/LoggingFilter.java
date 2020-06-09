// oDevArc june 2020
// package is intentionnaly a short namespace
package accessLogGetPOSTQueryString;

// import log4j2 libs to work with native Apache Tomcat 
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
// import spring to permit looking into parameters without side effetcs
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.context.request.async.WebAsyncUtils;
import org.springframework.web.util.ContentCachingResponseWrapper;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.annotation.WebInitParam;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Stream;

@WebFilter (value="/*", initParams= {
        @WebInitParam(name="force_charset", value="utf-8")
})
public class LoggingFilter implements Filter {
    private static final Logger log = LogManager.getLogger(LoggingFilter.class);
    private static final List<MediaType> VISIBLE_TYPES = Arrays.asList(
            MediaType.valueOf("text/*"),
            MediaType.APPLICATION_FORM_URLENCODED,
            MediaType.APPLICATION_JSON,
            MediaType.APPLICATION_XML,
            MediaType.valueOf("application/*+json"),
            MediaType.valueOf("application/*+xml"),
            MediaType.MULTIPART_FORM_DATA
    );
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {

    }

    @Override
    public void destroy() {

    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain filterChain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;


        if (isAsyncDispatch(httpRequest)) {
            filterChain.doFilter(request, response);
        } else {
            doFilterWrapped(wrapRequest(httpRequest), wrapResponse(httpResponse), filterChain);
        }

    }


    protected boolean isAsyncDispatch(HttpServletRequest request) {
        return WebAsyncUtils.getAsyncManager(request).hasConcurrentResult();
    }

    protected void doFilterWrapped(ContentCachingRequestWrapper2 request, ContentCachingResponseWrapper response, FilterChain filterChain) throws ServletException, IOException {
        try {
            beforeRequest(request, response);
            filterChain.doFilter(request, response);
        }
        finally {
            afterRequest(request, response);
            response.copyBodyToResponse();
        }
    }

    // this method is designed to have hands on the behavior of the requests paths
    // before send it to the normal path into Tomcat 
    protected void beforeRequest(ContentCachingRequestWrapper2 request, ContentCachingResponseWrapper response) {

        //logRequestHeader(request, request.getRemoteAddr() + "|>");
        // grab the parameters from the queryString in GET
        // this doesn't work for SOAP XML GET : the getQueryString return empty string
    	// grabb the parameters and put these (if these are STRING type) into the "attribute" named 'request_parameters'
        putRequestParametersFromHeaderInSpecificAttribute(request, "request_parameters");

    }

    // called after requests has been processed by Tomcat
    protected void afterRequest(ContentCachingRequestWrapper2 request, ContentCachingResponseWrapper response) {

        //logRequestBody(request, request.getRemoteAddr() + "|>");
        // grab the parameters in POST
        // POST request body is only readable AFTER REQUEST (I don't know why !)
        //putRequestParametersFromHeaderInSpecificAttribute(request, "request_parameters");
        //logResponse(response, request.getRemoteAddr() + "|<");
    }

    // put request parameters from header in specific attribute (callable by tomcat log4j2 accesslogs pattern
    private static void putRequestParametersFromHeaderInSpecificAttribute(ContentCachingRequestWrapper2 request, String attributeName) {

        StringBuffer output = new StringBuffer();
        
        // write into the custom log file located in /filter/conf_arcgis/log4j2.xml
        log.debug("{} {}", "grabb parameters from the request", request.getRequestURI());
        request.getParameterMap();

        // be aware that for SOAP XML request the querystring is empty
        // in this case we must use %q pattern in accesslog Tomcat config /tomcat/conf/server.xml to get querystring everytime
        if (request.getMethod().equals("GET")) {
            // GET request expose directly the parameters in the queryString
            String queryString = request.getQueryString();
            if (queryString != null) {
                output.append("?" + queryString);
            } else {
                output.append("?");
            }
            // adding the parameters in the "request_parameters" request attribute which can be grab from the standard Tomcat access log logger
            request.setAttribute(attributeName, output);
        }

        // nice java way but difficult to modify
        // here I want to take only the first which contain the real GET/POST parameters
        /*Collections.list(request.getHeaderNames()).forEach(headerName ->
                Collections.list(request.getHeaders(headerName)).forEach(headerValue ->
                        output.append("|\""+headerName+"|\"="+headerValue+"|\"")));*/


        // for POST request we must get parameters from the body
        if ("POST".equals(request.getMethod())) {
            byte[] content = request.getContentAsByteArray();
            if (content.length > 0) {
                output.append("?");
                String contentType = request.getContentType();
                String contentEncoding = request.getCharacterEncoding();
                MediaType mediaType = MediaType.valueOf(contentType);

                boolean visible = VISIBLE_TYPES.stream().anyMatch(visibleType -> visibleType.includes(mediaType));
                if (visible) {
                    try {
                        String contentString = new String(content, contentEncoding);
                        //Stream.of(contentString.split("\r\n|\r|\n")).forEach(line -> output.append("||" + line));
                        contentString = contentString.replace("\n", "").replace("\r", "").replace("   ", "");
                        output.append(contentString);
                    } catch (UnsupportedEncodingException e) {
                        output.append("error_getting_request_content_from_servletfilter");// + content.length);
                    }
                }
            }
            // adding the parameters in the "request_parameters" request attribute which can be grab from the standard Tomcat access log logger
            request.setAttribute(attributeName, output);
        }

    }

    private static void logRequestHeader(ContentCachingRequestWrapper2 request, String prefix) {
        String queryString = request.getQueryString();
        if (queryString == null) {
            log.info("{} {} {}", prefix, request.getMethod(), request.getRequestURI());
        } else {
            log.info("{} {} {}?{}", prefix, request.getMethod(), request.getRequestURI(), queryString);
        }
        Collections.list(request.getHeaderNames()).forEach(headerName ->
                Collections.list(request.getHeaders(headerName)).forEach(headerValue ->
                        log.info("{} {}: {}", prefix, headerName, headerValue)));
        log.info("{}", prefix);
    }

    private static void logRequestBody(ContentCachingRequestWrapper2 request, String prefix) {
        byte[] content = request.getContentAsByteArray();
        if (content.length > 0) {
            logContent(content, request.getContentType(), request.getCharacterEncoding(), prefix);
        }
    }

    private static void logResponse(ContentCachingResponseWrapper response, String prefix) {
        int status = response.getStatus();
        log.info("{} {} {}", prefix, status, HttpStatus.valueOf(status).getReasonPhrase());
        response.getHeaderNames().forEach(headerName ->
                response.getHeaders(headerName).forEach(headerValue ->
                        log.info("{} {}: {}", prefix, headerName, headerValue)));
        log.info("{}", prefix);
        byte[] content = response.getContentAsByteArray();
        if (content.length > 0) {
            logContent(content, response.getContentType(), response.getCharacterEncoding(), prefix);
        }
    }

    private static void logContent(byte[] content, String contentType, String contentEncoding, String prefix) {
        MediaType mediaType = MediaType.valueOf(contentType);
        boolean visible = VISIBLE_TYPES.stream().anyMatch(visibleType -> visibleType.includes(mediaType));
        if (visible) {
            try {
                String contentString = new String(content, contentEncoding);
                Stream.of(contentString.split("\r\n|\r|\n")).forEach(line -> log.info("{} {}", prefix, line));
            } catch (UnsupportedEncodingException e) {
                log.info("{} [{} bytes content]", prefix, content.length);
            }
        } else {
            log.info("{} [{} bytes content]", prefix, content.length);
        }
    }

    private static ContentCachingRequestWrapper2 wrapRequest(HttpServletRequest request) {
        if (request instanceof ContentCachingRequestWrapper2) {
            return (ContentCachingRequestWrapper2) request;
        } else {
            return new ContentCachingRequestWrapper2(request);
        }
    }

    private static ContentCachingResponseWrapper wrapResponse(HttpServletResponse response) {
        if (response instanceof ContentCachingResponseWrapper) {
            return (ContentCachingResponseWrapper) response;
        } else {
            return new ContentCachingResponseWrapper(response);
        }
    }

}
