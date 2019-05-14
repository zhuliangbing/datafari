<%-- Prevent the creation of a session --%>
<%@page import="java.nio.charset.StandardCharsets"%>
<%@page import="java.net.URLEncoder"%>
<%@ page session="false"%>
<%@ page contentType="text/html;charset=utf-8"%>
<%

%>
<html>
<head>
<title>Redirect</title>
<%
String url = request.getParameter("url");
String baseUrl = url.substring(0, url.lastIndexOf("/") + 1);
if(baseUrl.startsWith("file:")) {
	String filename = url.substring(url.lastIndexOf("/") + 1);
	filename = URLEncoder.encode(filename, StandardCharsets.UTF_8.name()).replaceAll("\\+", "%20");
	url = baseUrl + filename;
}
%>
<meta http-equiv="refresh" content="0;URL='<%= url %>'">
</head>
<body>
</body>
</html>