<!--- for the load balancer - RJ 2019 --->
<cfquery name="qPing" datasource="#request.dsn#">
SELECT 1
</cfquery>
<cfoutput>OK</cfoutput>
