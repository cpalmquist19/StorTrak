<!--- StorTrak app settings - GH 2006 --->
<cfapplication name="StorTrak"
	sessionmanagement="yes"
	sessiontimeout="#CreateTimeSpan(0,8,0,0)#">

<!--- dsn name. set up in the cf admin --->
<cfset request.dsn = "stortrak">

<!--- defaults --->
<cfparam name="session.fac" default="1">
<cfparam name="session.uname" default="">

<!--- make sure there logged in. login + ping pages are ok without - GH 2/06 --->
<cfif NOT IsDefined("session.uid")>
	<cfif NOT FindNoCase("login.cfm", cgi.script_name) AND NOT FindNoCase("ping.cfm", cgi.script_name)>
		<cflocation url="login.cfm">
	</cfif>
</cfif>

<!--- facility dropdown in the header sends ?setfac= --->
<cfif IsDefined("url.setfac")>
	<cfset session.fac = url.setfac>
</cfif>
