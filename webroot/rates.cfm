<!--- rate grid - GH 2006 --->
<!--- 3/07 one grid per facility - GH --->
<cfset msg = "">

<cfquery name="qRates" datasource="#request.dsn#">
SELECT fac, sz, utype, mo_rate, rate_old FROM rates ORDER BY fac, utype, sz
</cfquery>

<cfif IsDefined("form.dosave")>
	<cfloop query="qRates">
		<cfif IsDefined("form.rate_#fac#_#sz#_#utype#")>
			<cfset newRate = Evaluate("form.rate_#fac#_#sz#_#utype#")>
			<cfquery name="qUpdRate" datasource="#request.dsn#">
			UPDATE rates SET rate_old = mo_rate, mo_rate = #newRate#
			WHERE fac = #fac# AND sz = '#sz#' AND utype = #utype#
			</cfquery>
		</cfif>
	</cfloop>
	<cfset msg = "Rates saved.">

	<cfquery name="qRates" datasource="#request.dsn#">
	SELECT fac, sz, utype, mo_rate, rate_old FROM rates ORDER BY fac, utype, sz
	</cfquery>
</cfif>

<cfquery name="qFacs2" datasource="#request.dsn#">
SELECT FacID, FacNm FROM tblFacility ORDER BY FacID
</cfquery>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Rate Grid</b></font><br><br>

<cfoutput>
<cfif msg NEQ "">
	<font face="Verdana" size="2" color="##CC0000"><b>#msg#</b></font><br><br>
</cfif>
</cfoutput>

<form action="rates.cfm" method="post">
<input type="hidden" name="dosave" value="1">

<cfloop query="qFacs2">
	<cfset thisFac = qFacs2.FacID>
	<cfquery name="qSizes" dbtype="query">
	SELECT DISTINCT sz FROM qRates WHERE fac = #thisFac# ORDER BY sz
	</cfquery>

	<cfoutput>
	<font face="Verdana" size="2"><b>#qFacs2.FacNm#</b></font><br>
	</cfoutput>
	<table border="0" cellpadding="3" cellspacing="0" width="600" style="border:1px solid #99AABB;">
	<tr bgcolor="#336699">
		<td><font color="#FFFFFF"><b>Size</b></font></td>
		<td><font color="#FFFFFF"><b>Standard</b></font></td>
		<td><font color="#FFFFFF"><b>Drive-Up</b></font></td>
		<td><font color="#FFFFFF"><b>Climate</b></font></td>
		<td><font color="#FFFFFF"><b>Parking</b></font></td>
	</tr>
	<cfloop query="qSizes">
		<cfset thisSz = qSizes.sz>
		<tr <cfif qSizes.currentrow MOD 2 EQ 0>bgcolor="#F4F7FA"</cfif>>
			<cfoutput><td><b>#thisSz#</b></td></cfoutput>
			<cfloop from="1" to="4" index="ut">
				<cfquery name="qCell" dbtype="query">
				SELECT mo_rate, rate_old FROM qRates WHERE fac = #thisFac# AND sz = '#thisSz#' AND utype = #ut#
				</cfquery>
				<td>
				<cfif qCell.recordcount GT 0>
					<cfoutput>
					$<input type="text" name="rate_#thisFac#_#thisSz#_#ut#" size="7" value="#Trim(NumberFormat(qCell.mo_rate, '9999.99'))#">
					<cfif qCell.rate_old NEQ ""><br><font size="1" color="##666666">was #DollarFormat(qCell.rate_old)#</font></cfif>
					</cfoutput>
				<cfelse>
					&nbsp;
				</cfif>
				</td>
			</cfloop>
		</tr>
	</cfloop>
	</table>
	<br>
</cfloop>

<input type="submit" value="Save Rates">
</form>

<cfinclude template="ftr.cfm">
