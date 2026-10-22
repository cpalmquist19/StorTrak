<!--- settings - GH 2006 --->
<cfset msg = "">

<cfquery name="qSet" datasource="#request.dsn#">
SELECT k, v FROM settings ORDER BY k
</cfquery>

<cfif IsDefined("form.dosave")>
	<cfloop query="qSet">
		<cfif IsDefined("form.v_#qSet.k#")>
			<cfquery name="qUpdSet" datasource="#request.dsn#">
			UPDATE settings SET v = '#Evaluate("form.v_#qSet.k#")#' WHERE k = '#qSet.k#'
			</cfquery>
		</cfif>
	</cfloop>
	<cfset msg = "Settings saved.">

	<cfquery name="qSet" datasource="#request.dsn#">
	SELECT k, v FROM settings ORDER BY k
	</cfquery>
</cfif>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Settings</b></font><br><br>

<cfoutput>
<cfif msg NEQ "">
	<font face="Verdana" size="2" color="##CC0000"><b>#msg#</b></font><br><br>
</cfif>

<form action="settings.cfm" method="post">
<input type="hidden" name="dosave" value="1">
<table border="0" cellpadding="4" cellspacing="0" width="500" style="border:1px solid ##99AABB;">
<tr bgcolor="##336699">
	<td><font color="##FFFFFF"><b>Setting</b></font></td>
	<td><font color="##FFFFFF"><b>Value</b></font></td>
</tr>
<cfloop query="qSet">
<tr>
	<td><b>#qSet.k#</b></td>
	<td><input type="text" name="v_#qSet.k#" size="30" value="#qSet.v#"></td>
</tr>
</cfloop>
<tr>
	<td colspan="2"><font size="1" color="##666666">Last changed by #session.uname#</font></td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td><input type="submit" value="Save Settings"></td>
</tr>
</table>
</form>
</cfoutput>

<cfinclude template="ftr.cfm">
