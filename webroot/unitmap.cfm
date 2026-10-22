<!--- unit map. shows every unit by bldg - GH 2006 --->
<cfif IsDefined("url.fac")>
	<cfset fac = url.fac>
<cfelse>
	<cfset fac = session.fac>
</cfif>

<cfquery name="qUnits" datasource="#request.dsn#">
SELECT u.unit_id, u.unit_no, u.sz, u.utype, u.stat, LEFT(u.unit_no,1) AS bldg,
	t.fname, t.lname, t.ugc
FROM units u
LEFT JOIN rental r ON r.unit_id = u.unit_id AND r.moveout_dt IS NULL
LEFT JOIN tenant t ON t.TenantID = r.tid
WHERE u.fac = #fac#
ORDER BY bldg, u.unit_no, u.unit_id
</cfquery>

<cfquery name="qFac" datasource="#request.dsn#">
SELECT FacNm FROM tblFacility WHERE FacID = #fac#
</cfquery>

<cfset nVac = 0>
<cfset nRnt = 0>
<cfset nOth = 0>

<cfinclude template="hdr.cfm">

<cfoutput>
<font face="Verdana" size="3"><b>Unit Map - #qFac.FacNm#</b></font><br><br>
</cfoutput>

<cfoutput query="qUnits" group="bldg">
	<font face="Verdana" size="2"><b>Building #bldg#</b></font>
	<table border="0" cellpadding="0" cellspacing="3">
	<tr>
	<cfset i = 0>
	<cfoutput group="unit_id">
		<!--- colors by stat --->
		<cfif stat EQ 1>
			<cfset clr = "##99FF99">
		<cfelseif stat EQ 2>
			<cfset clr = "##6699FF">
		<cfelseif stat EQ 3>
			<cfset clr = "##FFFF66">
		<cfelseif stat EQ 4>
			<cfset clr = "##999999">
		<cfelseif stat EQ 5>
			<cfset clr = "##CC99FF">
		<cfelseif stat EQ 6>
			<cfset clr = "##FF9933">
		<cfelseif stat EQ 7>
			<cfset clr = "##FF3333">
		<cfelseif stat EQ 8>
			<cfset clr = "##CC6666">
		<cfelse>
			<cfset clr = "##FFFFFF">
		</cfif>

		<cfif stat EQ 1>
			<cfset nVac = nVac + 1>
		<cfelseif stat EQ 2>
			<cfset nRnt = nRnt + 1>
		<cfelse>
			<cfset nOth = nOth + 1>
		</cfif>

		<cfif i GT 0 AND i MOD 12 EQ 0></tr><tr></cfif>
		<cfset i = i + 1>
		<td class="ucell" bgcolor="#clr#" <cfif lname NEQ "">title="#fname# #lname# - gate #ugc#"</cfif>>
			<b>#unit_no#</b><br>#sz#
			<cfif lname NEQ ""><br>#lname#</cfif>
		</td>
	</cfoutput>
	</tr>
	</table>
	<br>
</cfoutput>

<cfoutput>
<table border="0" cellpadding="4" cellspacing="0" style="border:1px solid ##999999;">
<tr>
	<td><b>Vacant:</b> #nVac#</td>
	<td><b>Rented:</b> #nRnt#</td>
	<td><b>Other:</b> #nOth#</td>
	<td><b>Total:</b> #nVac + nRnt + nOth#</td>
</tr>
</table>
</cfoutput>
<br>

<!--- legend --->
<table border="0" cellpadding="3" cellspacing="2">
<tr>
	<td bgcolor="#99FF99" class="ucell">Vacant</td>
	<td bgcolor="#6699FF" class="ucell">Rented</td>
	<td bgcolor="#FFFF66" class="ucell">Reserved</td>
	<td bgcolor="#999999" class="ucell">Damaged</td>
	<td bgcolor="#CC99FF" class="ucell">Company</td>
	<td bgcolor="#FF9933" class="ucell">Overlock</td>
	<td bgcolor="#FF3333" class="ucell">Lien</td>
	<td bgcolor="#CC6666" class="ucell">Auction</td>
	<td bgcolor="#FFFFFF" class="ucell">Unknown</td>
</tr>
</table>

<cfinclude template="ftr.cfm">
