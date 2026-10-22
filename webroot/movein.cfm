<!--- move in - GH 2006 --->
<!--- 10/06 first version, 2/07 added lock sale - GH --->
<cfif IsDefined("url.fac")>
	<cfset fac = url.fac>
<cfelse>
	<cfset fac = session.fac>
</cfif>

<cfset done = 0>
<cfset msg = "">

<cfif IsDefined("form.unit_id")>
	<!--- new tenant or existing --->
	<cfif form.tenmode EQ "new">
		<cfset ugc = RandRange(10000, 99999)>
		<cfquery name="qInsTen" datasource="#request.dsn#">
		INSERT INTO tenant (fname, lname, ph1, ph2, email, addr1, city, st, zip, ugc, dt_added)
		VALUES ('#form.fname#', '#form.lname#', '#form.ph1#', '#form.ph2#', '#form.email#',
			'#form.addr1#', '#form.city#', '#form.st#', '#form.zip#', '#ugc#', NOW())
		</cfquery>
		<cfquery name="qNewTen" datasource="#request.dsn#">
		SELECT MAX(TenantID) AS newid FROM tenant
		</cfquery>
		<cfset tid = qNewTen.newid>
	<cfelse>
		<cfset tid = form.tid>
		<cfquery name="qOldTen" datasource="#request.dsn#">
		SELECT ugc FROM tenant WHERE TenantID = #tid#
		</cfquery>
		<cfset ugc = qOldTen.ugc>
	</cfif>

	<!--- paid thru = day before the 1st rent anniversary --->
	<cfset pdt = DateFormat(DateAdd("d", -1, DateAdd("m", 1, Now())), "yyyy-mm-dd")>

	<cfquery name="qInsRnt" datasource="#request.dsn#">
	INSERT INTO rental (tid, unit_id, movein_dt, moveout_dt, pdt, rnt_amt, dep_amt)
	VALUES (#tid#, #form.unit_id#, CURDATE(), NULL, '#pdt#', #form.rent#, #form.dep#)
	</cfquery>
	<cfquery name="qNewRnt" datasource="#request.dsn#">
	SELECT MAX(rid) AS newrid FROM rental
	</cfquery>
	<cfset rid = qNewRnt.newrid>

	<cfset payTot = form.rent + form.dep>

	<cfif form.dep GT 0>
		<cfquery name="qInsDep" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#rid#, 'D', #form.dep#, NOW(), 'DEPOSIT', '#session.uname#')
		</cfquery>
	</cfif>

	<cfquery name="qInsRent" datasource="#request.dsn#">
	INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
	VALUES (#rid#, 'R', #form.rent#, NOW(), 'RENT #DateFormat(Now(), "mm/dd/yyyy")#', '#session.uname#')
	</cfquery>

	<!--- lock sale. 12.99 plus sales tax - GH 2/07 --->
	<cfif IsDefined("form.lock")>
		<cfset lockTax = Round(12.99 * 0.0725 * 100) / 100>
		<cfset lockAmt = 12.99 + lockTax>
		<cfquery name="qInsLock" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#rid#, 'A', #lockAmt#, NOW(), 'LOCK 12.99 + tax', '#session.uname#')
		</cfquery>
		<cfset payTot = payTot + lockAmt>
	</cfif>
	<cfset payTot = Round(payTot * 100) / 100>

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
	VALUES (#rid#, 'P', #payTot#, NOW(), '#pmemo#', '#session.uname#')
	</cfquery>

	<cfquery name="qInsPmt" datasource="#request.dsn#">
	INSERT INTO payment (rid, amt, method, chk_no, cc_last4, dt, usr)
	VALUES (#rid#, #payTot#, '#form.method#',
		<cfif form.method EQ "CHECK">'#form.chkno#'<cfelse>NULL</cfif>,
		<cfif form.method EQ "CC">'#last4#'<cfelse>NULL</cfif>,
		NOW(), '#session.uname#')
	</cfquery>

	<cfquery name="qUpdUnit" datasource="#request.dsn#">
	UPDATE units SET stat = 2 WHERE unit_id = #form.unit_id#
	</cfquery>

	<cfset done = 1>
</cfif>

<cfquery name="qFacList" datasource="#request.dsn#">
SELECT FacID, FacNm FROM tblFacility ORDER BY FacID
</cfquery>

<!--- vacant units for the dropdown --->
<cfquery name="qVac" datasource="#request.dsn#">
SELECT u.unit_id, u.unit_no, u.sz, u.utype, r.mo_rate
FROM units u, rates r
WHERE u.fac = #fac# AND u.stat = 1
AND r.fac = u.fac AND r.sz = u.sz AND r.utype = u.utype
ORDER BY u.unit_no
</cfquery>

<cfif IsDefined("url.unit_id")>
	<cfquery name="qUnit" datasource="#request.dsn#">
	SELECT u.unit_id, u.unit_no, u.sz, u.utype, r.mo_rate
	FROM units u, rates r
	WHERE u.unit_id = #url.unit_id#
	AND r.fac = u.fac AND r.sz = u.sz AND r.utype = u.utype
	</cfquery>
	<cfquery name="qTens" datasource="#request.dsn#">
	SELECT TenantID, fname, lname, ph1 FROM tenant ORDER BY lname, fname
	</cfquery>
</cfif>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Move In</b></font><br><br>

<cfif done>
	<cfoutput>
	<table border="0" cellpadding="4" cellspacing="0" width="500" style="border:1px solid ##99AABB;">
	<tr bgcolor="##336699">
		<td><font face="Verdana" size="2" color="##FFFFFF"><b>Move in complete</b></font></td>
	</tr>
	<tr>
		<td>
			Rental ###rid# created. Paid thru #pdt#.<br>
			Payment of #DollarFormat(payTot)# posted.<br>
			Gate code: <b>#ugc#</b><br><br>
			<a href="ledger.cfm?rid=#rid#">View ledger</a> &nbsp;|&nbsp; <a href="movein.cfm">Another move in</a>
		</td>
	</tr>
	</table>
	</cfoutput>
<cfelse>

<!--- step 1: facility + unit --->
<cfoutput>
<form action="movein.cfm" method="get">
<table border="0" cellpadding="4" cellspacing="0">
<tr>
	<td>Facility:</td>
	<td>
		<select name="fac" onchange="location.href='movein.cfm?fac=' + this.value;">
		<cfloop query="qFacList">
			<option value="#qFacList.FacID#" <cfif qFacList.FacID EQ fac>selected</cfif>>#qFacList.FacNm#</option>
		</cfloop>
		</select>
	</td>
</tr>
<tr>
	<td>Vacant unit:</td>
	<td>
		<select name="unit_id">
		<cfloop query="qVac">
			<option value="#qVac.unit_id#" <cfif IsDefined("url.unit_id") AND qVac.unit_id EQ url.unit_id>selected</cfif>>#qVac.unit_no# - #qVac.sz# - #DollarFormat(qVac.mo_rate)#/mo</option>
		</cfloop>
		</select>
		(#qVac.recordcount# vacant)
	</td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td><input type="submit" value="Next &gt;&gt;"></td>
</tr>
</table>
</form>
</cfoutput>

<!--- step 2: tenant + terms --->
<cfif IsDefined("url.unit_id")>
<cfif qUnit.recordcount EQ 0>
	<font face="Verdana" size="2" color="#CC0000"><b>Unit not found.</b></font>
<cfelse>
<cfoutput>
<hr>
<font face="Verdana" size="2"><b>Unit #qUnit.unit_no# (#qUnit.sz#) - street rate #DollarFormat(qUnit.mo_rate)#</b></font><br><br>

<form action="movein.cfm" method="post">
<input type="hidden" name="fac" value="#fac#">
<input type="hidden" name="unit_id" value="#qUnit.unit_id#">
<table border="0" cellpadding="4" cellspacing="0">
<tr bgcolor="##E8EEF4">
	<td colspan="2"><input type="radio" name="tenmode" value="old"> <b>Existing tenant</b></td>
</tr>
<tr>
	<td>Tenant:</td>
	<td>
		<select name="tid">
		<cfloop query="qTens">
			<option value="#qTens.TenantID#">#qTens.lname#, #qTens.fname# - #qTens.ph1#</option>
		</cfloop>
		</select>
	</td>
</tr>
<tr bgcolor="##E8EEF4">
	<td colspan="2"><input type="radio" name="tenmode" value="new" checked> <b>New tenant</b></td>
</tr>
<tr><td>First name:</td><td><input type="text" name="fname" size="20"></td></tr>
<tr><td>Last name:</td><td><input type="text" name="lname" size="20"></td></tr>
<tr><td>Phone:</td><td><input type="text" name="ph1" size="15"></td></tr>
<tr><td>Alt phone / email:</td><td><input type="text" name="ph2" size="30"></td></tr>
<tr><td>Email:</td><td><input type="text" name="email" size="30"></td></tr>
<tr><td>Address:</td><td><input type="text" name="addr1" size="30"></td></tr>
<tr><td>City:</td><td><input type="text" name="city" size="20"></td></tr>
<tr><td>State:</td><td><input type="text" name="st" size="2" maxlength="2" value="NC"></td></tr>
<tr><td>Zip:</td><td><input type="text" name="zip" size="10"></td></tr>
<tr bgcolor="##E8EEF4">
	<td colspan="2"><b>Terms</b></td>
</tr>
<tr><td>Monthly rent:</td><td><input type="text" name="rent" size="10" value="#qUnit.mo_rate#"></td></tr>
<tr><td>Deposit:</td><td><input type="text" name="dep" size="10" value="25"></td></tr>
<tr><td>Sell a lock:</td><td><input type="checkbox" name="lock" value="1"> $12.99 + tax</td></tr>
<tr bgcolor="##E8EEF4">
	<td colspan="2"><b>Payment</b></td>
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
<tr><td>Check ##:</td><td><input type="text" name="chkno" size="10"></td></tr>
<tr><td>Card number:</td><td><input type="text" name="ccnum" size="20"></td></tr>
<tr>
	<td>&nbsp;</td>
	<td><input type="submit" value="Move In"></td>
</tr>
</table>
</form>
</cfoutput>
</cfif>
</cfif>

</cfif>

<cfinclude template="ftr.cfm">
