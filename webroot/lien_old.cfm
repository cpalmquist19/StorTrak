<!--- lien list - GH 2006 --->
<!--- 5/06 first version - GH --->
<cfparam name="session.lienmsg2" default="">

<cfif IsDefined("url.act") AND url.act EQ "sale" AND IsDefined("url.lien_id") AND IsDefined("url.rid")>
	<cfif IsDefined("form.saledt") AND IsDate(form.saledt) AND IsDefined("form.saleamt") AND Val(form.saleamt) GT 0>
		<cfquery name="qRu" datasource="#request.dsn#">
		SELECT unit_id FROM rental WHERE rid = #url.rid#
		</cfquery>
		<cfset sdt = DateFormat(ParseDateTime(form.saledt), "yyyy-mm-dd")>
		<cfset samt = Val(form.saleamt)>

		<cfquery name="qInsLed" datasource="#request.dsn#">
		INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
		VALUES (#url.rid#, 'P', #samt#, '#sdt# #TimeFormat(Now(), "HH:mm:ss")#', 'LIEN SALE', '#session.uname#')
		</cfquery>
		<cfquery name="qInsPmt" datasource="#request.dsn#">
		INSERT INTO payment (rid, amt, method, chk_no, cc_last4, dt, usr)
		VALUES (#url.rid#, #samt#, 'SALE', NULL, NULL, '#sdt# #TimeFormat(Now(), "HH:mm:ss")#', '#session.uname#')
		</cfquery>
		<cfquery name="qUpdLn" datasource="#request.dsn#">
		UPDATE lien SET lnstat = 4, sale_dt = '#sdt#', sale_amt = #samt# WHERE lien_id = #url.lien_id#
		</cfquery>
		<cfquery name="qUpdRent" datasource="#request.dsn#">
		UPDATE rental SET moveout_dt = '#sdt#' WHERE rid = #url.rid#
		</cfquery>
		<cfquery name="qUpdU" datasource="#request.dsn#">
		UPDATE units SET stat = 1 WHERE unit_id = #qRu.unit_id#
		</cfquery>
		<cfset session.lienmsg2 = "Sale recorded.">
	<cfelse>
		<cfset session.lienmsg2 = "Enter a sale date and amount.">
	</cfif>
	<cflocation url="lien_old.cfm?rid=#url.rid#">
</cfif>

<cfquery name="qLien" datasource="#request.dsn#">
SELECT l.lien_id, l.rid, l.lnstat, l.notice1_dt, l.notice2_dt, l.sale_dt, l.sale_amt,
	r.pdt, r.moveout_dt, t.fname, t.lname, u.unit_no, f.FacNm
FROM lien l, rental r, tenant t, units u, tblFacility f
WHERE r.rid = l.rid AND t.TenantID = r.tid AND u.unit_id = r.unit_id AND f.FacID = u.fac
<cfif IsDefined("url.rid")>
AND l.rid = #url.rid#
<cfelse>
AND l.lnstat <> 4 AND r.moveout_dt IS NULL
</cfif>
ORDER BY t.lname, t.fname, l.lien_id
</cfquery>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Lien List</b></font><br><br>

<cfoutput>
<cfif session.lienmsg2 NEQ "">
	<font face="Verdana" size="2" color="##CC0000"><b>#session.lienmsg2#</b></font><br><br>
	<cfset session.lienmsg2 = "">
</cfif>

<font face="Verdana" size="2"><b>#qLien.recordcount# lien(s)</b></font><br>
</cfoutput>

<cfif qLien.recordcount GT 0>
<table border="0" cellpadding="3" cellspacing="0" width="800" style="border:1px solid #99AABB;">
<tr bgcolor="#E8EEF4">
	<td><b>Rental</b></td>
	<td><b>Tenant</b></td>
	<td><b>Unit</b></td>
	<td><b>Paid Thru</b></td>
	<td><b>Stage</b></td>
	<td><b>Notice 1</b></td>
	<td><b>Notice 2</b></td>
	<td><b>Sale</b></td>
	<td><b>&nbsp;</b></td>
</tr>
<cfoutput query="qLien">
<tr <cfif qLien.currentrow MOD 2 EQ 0>bgcolor="##F4F7FA"</cfif>>
	<td><a href="ledger.cfm?rid=#rid#">###rid#</a></td>
	<td>#lname#, #fname#</td>
	<td><font size="1">#FacNm#</font> #unit_no#</td>
	<td>#pdt#</td>
	<td>
	<cfif lnstat EQ 1>Notice 1
	<cfelseif lnstat EQ 2>Notice 2
	<cfelseif lnstat EQ 3>Auction
	<cfelseif lnstat EQ 4>Sold
	<cfelse>?</cfif>
	</td>
	<td>#DateFormat(notice1_dt, "mm/dd/yyyy")#</td>
	<td>#DateFormat(notice2_dt, "mm/dd/yyyy")#</td>
	<td>#DateFormat(sale_dt, "mm/dd/yyyy")#</td>
	<td>
	<cfif lnstat GTE 3 AND lnstat NEQ 4>
		<form action="lien_old.cfm?act=sale&rid=#rid#&lien_id=#lien_id#" method="post" style="margin:0px;">
		<input type="text" name="saledt" size="10" value="#DateFormat(Now(), 'mm/dd/yyyy')#">
		$<input type="text" name="saleamt" size="8">
		<input type="submit" value="Record Sale">
		</form>
	</cfif>
	</td>
</tr>
</cfoutput>
</table>
</cfif>
<br>
<a href="lien.cfm">Back to liens</a>

<cfinclude template="ftr.cfm">
