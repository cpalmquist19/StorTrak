<!--- move out - GH 2006 --->
<!--- 2/07 first version - GH --->
<cfif NOT IsDefined("url.rid")>
	<cflocation url="ledger.cfm">
</cfif>

<cfset msg = "">

<cfquery name="qRent" datasource="#request.dsn#">
SELECT r.rid, r.tid, r.unit_id, r.movein_dt, r.moveout_dt, r.pdt, r.rnt_amt, r.dep_amt,
	t.fname, t.lname, t.ph1, u.unit_no, u.sz, f.FacNm
FROM rental r, tenant t, units u, tblFacility f
WHERE r.rid = #url.rid# AND t.TenantID = r.tid AND u.unit_id = r.unit_id AND f.FacID = u.fac
</cfquery>

<cfif qRent.recordcount GT 0>
	<!--- balance - GH 2/07 --->
	<cfquery name="qCharges2" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #url.rid# AND typ IN ('R','L','D','X')
	</cfquery>
	<cfquery name="qPaid2" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #url.rid# AND typ = 'P'
	</cfquery>
	<cfset totChg2 = Val(qCharges2.tot)>
	<cfset totPd2 = Val(qPaid2.tot)>
	<cfset finBal = Round((totChg2 - totPd2) * 100) / 100>

	<!--- deposit comes off the balance first, whatever is left over is refunded
	      or written off so the rental ends up at zero - GH 2/07 --->
	<cfset dep = Val(qRent.dep_amt)>
	<cfset netBal = Round((finBal - dep) * 100) / 100>
	<cfif netBal LT 0>
		<cfset refund = -netBal>
	<cfelse>
		<cfset refund = 0>
	</cfif>
</cfif>

<cfif IsDefined("form.dosub") AND qRent.recordcount GT 0>
	<cfquery name="qUpdRent" datasource="#request.dsn#">
	UPDATE rental SET moveout_dt = CURDATE() WHERE rid = #url.rid#
	</cfquery>

	<cfif dep GT 0>
		<cfquery name="qInsDep" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#url.rid#, 'A', #-dep#, NOW(), 'apply deposit', '#session.uname#')
		</cfquery>
	</cfif>

	<cfif netBal LT 0>
		<cfquery name="qInsRef" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#url.rid#, 'A', #refund#, NOW(), 'refund deposit', '#session.uname#')
		</cfquery>
	<cfelseif netBal GT 0>
		<cfquery name="qInsWo" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#url.rid#, 'A', #-netBal#, NOW(), 'write off bal at moveout', '#session.uname#')
		</cfquery>
	</cfif>

	<cfquery name="qUpdUnit" datasource="#request.dsn#">
	UPDATE units SET stat = 1 WHERE unit_id = #qRent.unit_id#
	</cfquery>

	<cfset msg = "Moved out. Deposit refund of " & DollarFormat(refund) & " due to tenant.">
</cfif>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Move Out</b></font><br><br>

<cfif qRent.recordcount EQ 0>
	<font face="Verdana" size="2" color="#CC0000"><b>Rental not found.</b></font>
<cfelse>
<cfoutput>
<cfif msg NEQ "">
	<font face="Verdana" size="2" color="##CC0000"><b>#msg#</b></font><br><br>
</cfif>

<table border="0" cellpadding="4" cellspacing="0" width="500" style="border:1px solid ##99AABB;">
<tr bgcolor="##336699">
	<td colspan="2"><font face="Verdana" size="2" color="##FFFFFF"><b>Rental ###qRent.rid# - #qRent.lname#, #qRent.fname#</b></font></td>
</tr>
<tr>
	<td><b>Facility</b></td><td>#qRent.FacNm#</td>
</tr>
<tr>
	<td><b>Unit</b></td><td>#qRent.unit_no# (#qRent.sz#)</td>
</tr>
<tr>
	<td><b>Move In</b></td><td>#DateFormat(qRent.movein_dt, "mm/dd/yyyy")#</td>
</tr>
<tr>
	<td><b>Final Balance</b></td><td><b>#DollarFormat(finBal)#</b></td>
</tr>
<tr>
	<td><b>Deposit Held</b></td><td>#DollarFormat(dep)#</td>
</tr>
<tr>
	<td><b>Deposit Refund Due</b></td><td><b>#DollarFormat(refund)#</b></td>
</tr>
</table>
<br>

<form action="moveout.cfm?rid=#qRent.rid#" method="post">
<input type="hidden" name="dosub" value="1">
<input type="submit" value="Move Out">
</form>
<a href="ledger.cfm?rid=#qRent.rid#">Back to ledger</a>
</cfoutput>
</cfif>

<cfinclude template="ftr.cfm">
