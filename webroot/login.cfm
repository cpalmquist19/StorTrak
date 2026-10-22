<!--- login page - GH 2006 --->
<cfset msg = "">

<cfif IsDefined("form.uname")>
	<!--- CF hash comes back in caps, the db has lowercase - GH --->
	<cfset pw = LCase(Hash(form.pw))>

	<cfquery name="qLogin" datasource="#request.dsn#">
	SELECT * FROM users
	WHERE uname = '#form.uname#' AND pw = '#pw#'
	</cfquery>

	<cfif qLogin.recordcount GT 0>
		<cfset session.uid = qLogin.uid>
		<cfset session.uname = qLogin.uname>
		<cfset session.lvl = qLogin.lvl>
		<cfset session.fname = qLogin.fname>
		<cfset session.fac = 1>
		<cflocation url="index.cfm">
	<cfelse>
		<cfset msg = "Invalid login for " & form.uname>
	</cfif>
</cfif>

<html>
<head>
<title>StorTrak - Login</title>
<link rel="stylesheet" href="css/main.css">
</head>
<body bgcolor="#FFFFFF">
<br><br><br>
<table width="320" align="center" border="0" cellpadding="6" cellspacing="0" style="border:1px solid #336699;">
<tr>
	<td bgcolor="#336699" colspan="2"><font face="Verdana" size="3" color="#FFFFFF"><b>StorTrak Login</b></font></td>
</tr>
<cfoutput>
<cfif msg NEQ "">
<tr>
	<td colspan="2"><font face="Verdana" size="2" color="##CC0000"><b>#msg#</b></font></td>
</tr>
</cfif>
</cfoutput>
<form action="login.cfm" method="post">
<tr>
	<td><font face="Verdana" size="2">User:</font></td>
	<td><input type="text" name="uname" size="20"></td>
</tr>
<tr>
	<td><font face="Verdana" size="2">Password:</font></td>
	<td><input type="password" name="pw" size="20"></td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td><input type="submit" value="Login"></td>
</tr>
</form>
</table>
<p align="center"><font face="Verdana" size="1" color="#999999">Piedmont Stor-All</font></p>
</body>
</html>
