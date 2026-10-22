<!--- Placeholder: confirms the "stortrak" DSN connects. --->
<cfquery name="qPing" datasource="stortrak">
    SELECT 1 AS ok
</cfquery>
<html>
<head><title>StorTrak</title></head>
<body>
<p id="db-status">DB OK</p>
</body>
</html>
