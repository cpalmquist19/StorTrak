<!--- page header. include at top of every page - GH 2006 --->
<cfquery name="qFacs" datasource="#request.dsn#">
SELECT FacID, FacNm FROM tblFacility ORDER BY FacID
</cfquery>
<html>
<head>
<title>StorTrak</title>
<link rel="stylesheet" href="css/main.css">
</head>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<cfoutput>
<table width="100%" border="0" cellpadding="4" cellspacing="0">
<tr bgcolor="##336699">
	<td><font face="Verdana" size="4" color="##FFFFFF"><b>StorTrak</b></font></td>
	<td align="right">
		<font face="Verdana" size="2" color="##FFFFFF">
		Facility:
		<select name="setfac" onchange="location.href='?setfac=' + this.value;">
		<cfloop query="qFacs">
			<option value="#qFacs.FacID#" <cfif qFacs.FacID EQ session.fac>selected</cfif>>#qFacs.FacNm#</option>
		</cfloop>
		</select>
		&nbsp;|&nbsp; Logged in as #session.fname# &nbsp;|&nbsp; #DateFormat(Now(), "mm/dd/yyyy")#
		</font>
	</td>
</tr>
</table>
</cfoutput>
<table width="100%" border="0" cellpadding="0" cellspacing="0">
<tr>
	<td width="150" valign="top" bgcolor="#E8EEF4" style="border-right:1px solid #99AABB;">
		<cfinclude template="nav.cfm">
	</td>
	<td valign="top" style="padding:10px;">
