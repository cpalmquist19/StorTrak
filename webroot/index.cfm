<!--- Infrastructure smoke test: confirms Lucee can reach MySQL through the "stortrak" DSN
      and lists every table in the schema with its row count. --->
<cfsetting showdebugoutput="false">
<cfset dbOk = true>
<cfset tableCounts = []>
<cftry>
    <cfquery name="qCheck" datasource="stortrak">
        SELECT NOW() AS server_time, VERSION() AS mysql_version, DATABASE() AS db_name
    </cfquery>
    <cfquery name="qTables" datasource="stortrak">
        SELECT table_name AS tbl
        FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
        ORDER BY table_name
    </cfquery>
    <cfloop query="qTables">
        <!--- Table names come from the catalog, not user input. --->
        <cfquery name="qCount" datasource="stortrak">
            SELECT COUNT(*) AS n FROM `#qTables.tbl#`
        </cfquery>
        <cfset arrayAppend(tableCounts, {name: qTables.tbl, rows: qCount.n})>
    </cfloop>
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
    <h2>Tables (<span id="table-count">#arrayLen(tableCounts)#</span>)</h2>
    <table id="tables" border="1" cellpadding="4" cellspacing="0">
        <tr><th>Table</th><th>Rows</th></tr>
        <cfloop array="#tableCounts#" item="t">
            <tr><td>#encodeForHTML(t.name)#</td><td>#t.rows#</td></tr>
        </cfloop>
    </table>
<cfelse>
    <p id="db-status">DB ERROR</p>
    <pre>#encodeForHTML(dbError)#</pre>
</cfif>
</cfoutput>
</body>
</html>
