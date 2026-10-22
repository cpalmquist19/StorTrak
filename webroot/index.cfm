<!--- Infrastructure smoke test: confirms Lucee can reach MySQL through the "stortrak" DSN. --->
<cfsetting showdebugoutput="false">
<cfset dbOk = true>
<cftry>
    <cfquery name="qCheck" datasource="stortrak">
        SELECT NOW() AS server_time, VERSION() AS mysql_version, DATABASE() AS db_name
    </cfquery>
    <cfcatch type="any">
        <cfset dbOk = false>
        <cfset dbError = cfcatch.message & " " & cfcatch.detail>
    </cfcatch>
</cftry>
<!DOCTYPE html>
<html>
<head><title>StorTrak - connection check</title></head>
<body>
<h1>StorTrak connection check</h1>
<cfoutput>
<p>CFML engine: #server.lucee.version#</p>
<cfif dbOk>
    <p id="db-status">DB OK</p>
    <p>Database: #qCheck.db_name# (MySQL #qCheck.mysql_version#)</p>
    <p>Server time: #dateTimeFormat(qCheck.server_time, "yyyy-mm-dd HH:nn:ss")#</p>
<cfelse>
    <p id="db-status">DB ERROR</p>
    <pre>#encodeForHTML(dbError)#</pre>
</cfif>
</cfoutput>
</body>
</html>
