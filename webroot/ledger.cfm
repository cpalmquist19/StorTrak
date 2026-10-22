<!--- tenant search + ledger - GH 2006 --->
<!--- 11/06 added running balance, 1/07 added late fee note - GH --->
<cfif IsDefined("url.q")>
	<cfset q = Trim(url.q)>
<cfelse>
	<cfset q = "">
</cfif>

<cfif q NEQ "">
	<cfquery name="qFind" datasource="#request.dsn#">
	SELECT t.TenantID, t.fname, t.lname, t.ph1, r.rid, r.movein_dt, r.moveout_dt, r.pdt, u.unit_no, f.FacNm
	FROM tenant t, rental r, units u, tblFacility f
	WHERE r.tid = t.TenantID AND u.unit_id = r.unit_id AND f.FacID = u.fac
	AND (t.lname LIKE '%#q#%' OR t.ph1 LIKE '%#q#%'
		OR t.TenantID IN (SELECT r2.tid FROM rental r2, units u2 WHERE u2.unit_id = r2.unit_id AND u2.unit_no = '#q#'))
	ORDER BY t.lname, t.fname, t.TenantID, r.movein_dt DESC
	</cfquery>
</cfif>

<cfif IsDefined("url.rid")>
	<cfquery name="qRnt" datasource="#request.dsn#">
	SELECT r.rid, r.tid, r.movein_dt, r.moveout_dt, r.pdt, r.rnt_amt, r.dep_amt,
		t.fname, t.lname, t.ph1, u.unit_no, u.sz, f.FacNm
	FROM rental r, tenant t, units u, tblFacility f
	WHERE r.rid = #url.rid# AND t.TenantID = r.tid AND u.unit_id = r.unit_id AND f.FacID = u.fac
	</cfquery>

	<cfquery name="qLed" datasource="#request.dsn#">
	SELECT lid, typ, amt, dt, memo, usr
	FROM ledger
	WHERE rid = #url.rid#
	ORDER BY dt, lid
	</cfquery>

	<!--- balance. charges minus payments - GH 11/06 --->
	<cfquery name="qChg" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #url.rid# AND typ IN ('R','L','D','A','X')
	</cfquery>
	<cfquery name="qPd" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #url.rid# AND typ = 'P'
	</cfquery>
	<cfset chg = Val(qChg.tot)>
	<cfset pd = Val(qPd.tot)>
	<cfset bal = Round((chg - pd) * 100) / 100>

	<cfif qRnt.recordcount GT 0>
		<!--- past due if paid thru is before today - GH 12/06 --->
		<cfset pastDue = 0>
		<cfset today = DateFormat(Now(), "yyyy-mm-dd")>
		<cfif qRnt.moveout_dt EQ "" AND Compare(qRnt.pdt, today) LT 0>
			<cfset pastDue = 1>
		</cfif>

		<!--- late fee. grace/fee/pct come from the settings table - GH 1/07 --->
		<cfif pastDue>
			<cfquery name="qSet" datasource="#request.dsn#">
			SELECT k, v FROM settings WHERE k IN ('GRACE','LATEFEE','LATEPCT')
			</cfquery>
			<cfloop query="qSet">
				<cfif qSet.k EQ "GRACE"><cfset grace = Val(qSet.v)></cfif>
				<cfif qSet.k EQ "LATEFEE"><cfset flat = Val(qSet.v)></cfif>
				<cfif qSet.k EQ "LATEPCT"><cfset pct = Val(qSet.v)></cfif>
			</cfloop>

			<cfif Find("/", qRnt.pdt)>
				<cfset pdtDt = CreateDate(Right(qRnt.pdt, 4), Left(qRnt.pdt, 2), Mid(qRnt.pdt, 4, 2))>
			<cfelse>
				<cfset pdtDt = CreateDate(Left(qRnt.pdt, 4), Mid(qRnt.pdt, 6, 2), Mid(qRnt.pdt, 9, 2))>
			</cfif>
			<cfset dueDt = DateAdd("d", 1, pdtDt)>
			<cfset feeDt = DateAdd("d", grace + 1, dueDt)>
			<cfset pctFee = Round(qRnt.rnt_amt * pct) / 100>
			<cfif pctFee GT flat>
				<cfset lateFee = pctFee>
			<cfelse>
				<cfset lateFee = flat>
			</cfif>
		</cfif>
	</cfif>
</cfif>

<cfinclude template="hdr.cfm">

<cfoutput>
<font face="Verdana" size="3"><b>Tenant Ledger</b></font><br><br>

<form action="ledger.cfm" method="get">
<font face="Verdana" size="2">Find tenant (last name, phone or unit ##):</font>
<input type="text" name="q" size="20" value="#q#">
<input type="submit" value="Search">
</form>
<br>
</cfoutput>

<cfif q NEQ "">
	<cfoutput>
	<font face="Verdana" size="2"><b>#qFind.recordcount# rental(s) found for "#q#"</b></font><br><br>
	</cfoutput>

	<cfif qFind.recordcount GT 0>
	<table border="0" cellpadding="3" cellspacing="0" width="700" style="border:1px solid ##99AABB;">
	<cfoutput query="qFind" group="TenantID">
	<tr bgcolor="##E8EEF4">
		<td colspan="5"><b>#lname#, #fname#</b> &nbsp; #ph1#</td>
	</tr>
	<tr>
		<td><font size="1"><b>Facility</b></font></td>
		<td><font size="1"><b>Unit</b></font></td>
		<td><font size="1"><b>Move In</b></font></td>
		<td><font size="1"><b>Move Out</b></font></td>
		<td><font size="1"><b>Ledger</b></font></td>
	</tr>
	<cfoutput>
	<tr>
		<td>#FacNm#</td>
		<td>#unit_no#</td>
		<td>#DateFormat(movein_dt, "mm/dd/yyyy")#</td>
		<td><cfif moveout_dt EQ ""><font color="##006600"><b>ACTIVE</b></font><cfelse>#DateFormat(moveout_dt, "mm/dd/yyyy")#</cfif></td>
		<td><a href="ledger.cfm?rid=#rid#">view</a></td>
	</tr>
	</cfoutput>
	</cfoutput>
	</table>
	<br>
	</cfif>
</cfif>

<cfif IsDefined("url.rid")>
<cfif qRnt.recordcount EQ 0>
	<font face="Verdana" size="2" color="#CC0000"><b>Rental not found.</b></font>
<cfelse>
<cfoutput>
<table border="0" cellpadding="4" cellspacing="0" width="700" style="border:1px solid ##99AABB;">
<tr bgcolor="##336699">
	<td colspan="4"><font face="Verdana" size="2" color="##FFFFFF"><b>Rental ###qRnt.rid# - #qRnt.lname#, #qRnt.fname#</b></font></td>
</tr>
<tr>
	<td><b>Facility</b></td><td>#qRnt.FacNm#</td>
	<td><b>Unit</b></td><td>#qRnt.unit_no# (#qRnt.sz#)</td>
</tr>
<tr>
	<td><b>Phone</b></td><td>#qRnt.ph1#</td>
	<td><b>Rent</b></td><td>#DollarFormat(qRnt.rnt_amt)#</td>
</tr>
<tr>
	<td><b>Move In</b></td><td>#DateFormat(qRnt.movein_dt, "mm/dd/yyyy")#</td>
	<td><b>Move Out</b></td>
	<td><cfif qRnt.moveout_dt EQ "">&nbsp;<cfelse>#DateFormat(qRnt.moveout_dt, "mm/dd/yyyy")#</cfif></td>
</tr>
<tr>
	<td><b>Paid Thru</b></td>
	<td>#qRnt.pdt#
		<cfif pastDue>&nbsp;<font color="##CC0000"><b>PAST DUE</b></font></cfif></td>
	<td><b>Balance</b></td>
	<td><b>#DollarFormat(bal)#</b></td>
</tr>
<cfif pastDue>
<tr>
	<td colspan="4"><font color="##CC0000">A late fee of #DollarFormat(lateFee)# will post on #DateFormat(feeDt, "mm/dd/yyyy")#.</font></td>
</tr>
</cfif>
<tr>
	<td colspan="4">
		<a href="pmt.cfm?rid=#qRnt.rid#">Take Payment</a>
		<cfif qRnt.moveout_dt EQ ""> &nbsp;|&nbsp; <a href="moveout.cfm?rid=#qRnt.rid#">Move Out</a></cfif>
	</td>
</tr>
</table>
<br>

<table border="0" cellpadding="3" cellspacing="0" width="700" style="border:1px solid ##99AABB;">
<tr bgcolor="##E8EEF4">
	<td><b>Date</b></td>
	<td><b>Typ</b></td>
	<td align="right"><b>Amount</b></td>
	<td><b>Memo</b></td>
	<td><b>User</b></td>
	<td align="right"><b>Balance</b></td>
</tr>
<cfset run = 0>
<cfloop query="qLed">
	<cfif qLed.typ EQ "P">
		<cfset run = run - qLed.amt>
	<cfelse>
		<cfset run = run + qLed.amt>
	</cfif>
	<tr <cfif qLed.currentrow MOD 2 EQ 0>bgcolor="##F4F7FA"</cfif>>
		<td>#DateFormat(qLed.dt, "mm/dd/yyyy")# #TimeFormat(qLed.dt, "h:mm tt")#</td>
		<td>#qLed.typ#</td>
		<td align="right">#NumberFormat(qLed.amt, "999,999.00")#</td>
		<td>#qLed.memo#</td>
		<td>#qLed.usr#</td>
		<td align="right">#NumberFormat(Round(run * 100) / 100, "999,999.00")#</td>
	</tr>
</cfloop>
<tr bgcolor="##E8EEF4">
	<td colspan="5" align="right"><b>Total balance</b></td>
	<td align="right"><b>#NumberFormat(bal, "999,999.00")#</b></td>
</tr>
</table>
</cfoutput>
</cfif>
</cfif>

<cfinclude template="ftr.cfm">
