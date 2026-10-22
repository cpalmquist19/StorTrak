<!--- take payment - GH 2006 --->
<!--- 12/06 added check # and card fields - GH --->
<cfif NOT IsDefined("url.rid")>
	<cflocation url="ledger.cfm">
</cfif>

<cfset msg = "">

<cfquery name="qRental" datasource="#request.dsn#">
SELECT r.rid, r.tid, r.movein_dt, r.moveout_dt, r.pdt, r.rnt_amt, r.dep_amt,
	t.fname, t.lname, t.ph1, u.unit_no, u.sz, f.FacNm
FROM rental r, tenant t, units u, tblFacility f
WHERE r.rid = #url.rid# AND t.TenantID = r.tid AND u.unit_id = r.unit_id AND f.FacID = u.fac
</cfquery>

<cfif IsDefined("form.amt") AND qRental.recordcount GT 0>
	<cfset payAmt = Val(form.amt)>
	<cfif payAmt LTE 0>
		<cfset msg = "Enter an amount.">
	<cfelse>
		<cfset last4 = Right(Trim(form.ccnum), 4)>
		<cfif form.method EQ "CHECK">
			<cfset pmemo = "PMT CK ###form.chkno#">
		<cfelseif form.method EQ "CC">
			<cfset pmemo = "PMT CC x#last4#">
		<cfelse>
			<cfset pmemo = "PMT #form.method#">
		</cfif>

		<cfquery name="qInsLed" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#url.rid#, 'P', #payAmt#, NOW(), '#pmemo#', '#session.uname#')
		</cfquery>

		<cfquery name="qInsPmt" datasource="#request.dsn#">
		INSERT INTO payment (rid, amt, method, chk_no, cc_last4, dt, usr)
		VALUES (#url.rid#, #payAmt#, '#form.method#',
			<cfif form.method EQ "CHECK">'#form.chkno#'<cfelse>NULL</cfif>,
			<cfif form.method EQ "CC">'#last4#'<cfelse>NULL</cfif>,
			NOW(), '#session.uname#')
		</cfquery>

		<!--- full payment moves paid thru out a month. partials dont - GH 1/07 --->
		<cfif payAmt GTE qRental.rnt_amt>
			<cfif Find("/", qRental.pdt)>
				<cfset oldPdt = CreateDate(Right(qRental.pdt, 4), Left(qRental.pdt, 2), Mid(qRental.pdt, 4, 2))>
			<cfelse>
				<cfset oldPdt = CreateDate(Left(qRental.pdt, 4), Mid(qRental.pdt, 6, 2), Mid(qRental.pdt, 9, 2))>
			</cfif>
			<cfset newPdt = DateFormat(DateAdd("m", 1, oldPdt), "mm/dd/yyyy")>
			<cfquery name="qUpdPdt" datasource="#request.dsn#">
			UPDATE rental SET pdt = '#newPdt#' WHERE rid = #url.rid#
			</cfquery>
			<cfset qRental.pdt = newPdt>
		</cfif>

		<cfset msg = "Payment of " & DollarFormat(payAmt) & " posted.">
	</cfif>
</cfif>

<cfif qRental.recordcount GT 0>
	<!--- balance - GH 1/07 --->
	<cfquery name="qCharges" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #url.rid# AND typ IN ('R','L','D','A','X')
	</cfquery>
	<cfquery name="qPaid" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #url.rid# AND typ = 'P'
	</cfquery>
	<cfset totChg = Val(qCharges.tot)>
	<cfset totPd = Val(qPaid.tot)>
	<cfset curBal = Round((totChg - totPd) * 100) / 100>

	<!--- late fee. grace/fee/pct come from the settings table - GH 1/07 --->
	<cfquery name="qSettings" datasource="#request.dsn#">
	SELECT k, v FROM settings WHERE k IN ('GRACE','LATEFEE','LATEPCT')
	</cfquery>
	<cfloop query="qSettings">
		<cfif qSettings.k EQ "GRACE"><cfset grace2 = Val(qSettings.v)></cfif>
		<cfif qSettings.k EQ "LATEFEE"><cfset flat2 = Val(qSettings.v)></cfif>
		<cfif qSettings.k EQ "LATEPCT"><cfset pct2 = Val(qSettings.v)></cfif>
	</cfloop>

	<cfif Find("/", qRental.pdt)>
		<cfset pdtDt2 = CreateDate(Right(qRental.pdt, 4), Left(qRental.pdt, 2), Mid(qRental.pdt, 4, 2))>
	<cfelse>
		<cfset pdtDt2 = CreateDate(Left(qRental.pdt, 4), Mid(qRental.pdt, 6, 2), Mid(qRental.pdt, 9, 2))>
	</cfif>
	<cfset dueDt2 = DateAdd("d", 1, pdtDt2)>
	<cfset feeDt2 = DateAdd("d", grace2 + 1, dueDt2)>
	<cfset pctFee2 = Round(qRental.rnt_amt * pct2) / 100>
	<cfif pctFee2 GT flat2>
		<cfset lateFee2 = pctFee2>
	<cfelse>
		<cfset lateFee2 = flat2>
	</cfif>
</cfif>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Take Payment</b></font><br><br>

<cfif qRental.recordcount EQ 0>
	<font face="Verdana" size="2" color="#CC0000"><b>Rental not found.</b></font>
<cfelse>
<cfoutput>
<cfif msg NEQ "">
	<font face="Verdana" size="2" color="##CC0000"><b>#msg#</b></font><br><br>
</cfif>

<table border="0" cellpadding="4" cellspacing="0" width="500" style="border:1px solid ##99AABB;">
<tr bgcolor="##336699">
	<td colspan="2"><font face="Verdana" size="2" color="##FFFFFF"><b>Rental ###qRental.rid# - #qRental.lname#, #qRental.fname#</b></font></td>
</tr>
<tr>
	<td><b>Facility</b></td><td>#qRental.FacNm#</td>
</tr>
<tr>
	<td><b>Unit</b></td><td>#qRental.unit_no# (#qRental.sz#)</td>
</tr>
<tr>
	<td><b>Rent</b></td><td>#DollarFormat(qRental.rnt_amt)#</td>
</tr>
<tr>
	<td><b>Paid Thru</b></td><td>#qRental.pdt#</td>
</tr>
<tr>
	<td><b>Current Balance</b></td><td><b>#DollarFormat(curBal)#</b></td>
</tr>
<tr>
	<td colspan="2"><font color="##666666">If not paid, a late fee of #DollarFormat(lateFee2)# will post on #DateFormat(feeDt2, "mm/dd/yyyy")#.</font></td>
</tr>
</table>
<br>

<form action="pmt.cfm?rid=#qRental.rid#" method="post">
<table border="0" cellpadding="4" cellspacing="0">
<tr>
	<td>Amount:</td>
	<td><input type="text" name="amt" size="10"></td>
</tr>
<tr>
	<td>Method:</td>
	<td>
		<select name="method">
			<option value="CASH">CASH</option>
			<option value="CHECK">CHECK</option>
			<option value="CC">CC</option>
			<option value="MO">MO</option>
		</select>
	</td>
</tr>
<tr>
	<td>Check ##:</td>
	<td><input type="text" name="chkno" size="10"></td>
</tr>
<tr>
	<td>Card number:</td>
	<td><input type="text" name="ccnum" size="20"></td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td><input type="submit" value="Post Payment"></td>
</tr>
</table>
</form>
<a href="ledger.cfm?rid=#qRental.rid#">Back to ledger</a>
</cfoutput>
</cfif>

<cfinclude template="ftr.cfm">
