<!--- lien tracker - GH 2006 --->
<!--- 9/06 first cut. 4/07 added payment plans, notice buttons - GH --->
<cfparam name="session.lienmsg" default="">

<cfquery name="qRent" datasource="#request.dsn#">
SELECT r.rid, r.unit_id, r.pdt, r.rnt_amt, t.fname, t.lname, t.ph1, u.unit_no, f.FacNm,
	l.lien_id, l.lnstat, l.notice1_dt, l.notice2_dt, l.sale_dt
FROM rental r
INNER JOIN tenant t ON t.TenantID = r.tid
INNER JOIN units u ON u.unit_id = r.unit_id
INNER JOIN tblFacility f ON f.FacID = u.fac
LEFT JOIN lien l ON l.rid = r.rid
WHERE r.moveout_dt IS NULL
ORDER BY t.lname, t.fname, r.rid
</cfquery>

<cfset bals = StructNew()>
<cfset behind = StructNew()>
<cfloop query="qRent">
	<!--- balance - GH 4/07 --->
	<cfquery name="qSumChg" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #qRent.rid# AND typ IN ('R','L','D','A','X')
	</cfquery>
	<cfquery name="qSumPd" datasource="#request.dsn#">
	SELECT SUM(amt) AS tot FROM ledger WHERE rid = #qRent.rid# AND typ = 'P'
	</cfquery>
	<cfset sumChg = Val(qSumChg.tot)>
	<cfset sumPd = Val(qSumPd.tot)>
	<cfset rentBal = Round((sumChg - sumPd) * 100) / 100>

	<cfif rentBal GT 0>
		<cfif Find("/", qRent.pdt)>
			<cfset pdtDt3 = CreateDate(Right(qRent.pdt, 4), Left(qRent.pdt, 2), Mid(qRent.pdt, 4, 2))>
		<cfelse>
			<cfset pdtDt3 = CreateDate(Left(qRent.pdt, 4), Mid(qRent.pdt, 6, 2), Mid(qRent.pdt, 9, 2))>
		</cfif>
		<cfset bals[qRent.rid] = rentBal>
		<cfset behind[qRent.rid] = DateDiff("d", pdtDt3, Now())>
	</cfif>
</cfloop>

<cfif IsDefined("url.act") AND IsDefined("url.rid")>
	<cfset msg = "">

	<cfif IsDefined("url.lien_id") AND url.lien_id NEQ "">
		<cfquery name="qLn" datasource="#request.dsn#">
		SELECT lien_id, lnstat, sale_dt FROM lien WHERE lien_id = #url.lien_id# AND rid = #url.rid#
		</cfquery>
	<cfelse>
		<cfquery name="qLn" datasource="#request.dsn#">
		SELECT lien_id, lnstat, sale_dt FROM lien WHERE rid = #url.rid#
		</cfquery>
	</cfif>

	<cfquery name="qRu" datasource="#request.dsn#">
	SELECT unit_id FROM rental WHERE rid = #url.rid#
	</cfquery>

	<cfif NOT StructKeyExists(bals, url.rid)>
		<cfset msg = "Rental not on the lien list.">
	<cfelseif url.act EQ "n1">
		<cfif qLn.recordcount GT 0>
			<cfset msg = "That rental already has a lien record.">
		<cfelseif behind[url.rid] LT 31>
			<cfset msg = "Not far enough behind for notice 1.">
		<cfelse>
			<cfquery name="qInsLn" datasource="#request.dsn#">
			INSERT INTO lien (rid, lnstat, notice1_dt) VALUES (#url.rid#, 1, CURDATE())
			</cfquery>
			<cfquery name="qUpdU" datasource="#request.dsn#">
			UPDATE units SET stat = 7 WHERE unit_id = #qRu.unit_id#
			</cfquery>
			<cfset msg = "Notice 1 sent.">
		</cfif>
	<cfelseif qLn.recordcount EQ 0>
		<cfset msg = "No lien record for that rental.">
	<cfelseif url.act EQ "n2">
		<cfif qLn.lnstat NEQ 1>
			<cfset msg = "Notice 1 has to go out first.">
		<cfelseif behind[url.rid] LT 52>
			<cfset msg = "Not far enough behind for notice 2.">
		<cfelse>
			<cfquery name="qUpdLn" datasource="#request.dsn#">
			UPDATE lien SET lnstat = 2, notice2_dt = CURDATE() WHERE lien_id = #url.lien_id#
			</cfquery>
			<cfset msg = "Notice 2 sent.">
		</cfif>
	<cfelseif url.act EQ "auct">
		<cfif qLn.lnstat NEQ 2>
			<cfset msg = "Notice 2 has to go out first.">
		<cfelseif behind[url.rid] LT 80>
			<cfset msg = "Not far enough behind for an auction.">
		<cfelseif NOT IsDefined("form.auctdt") OR NOT IsDate(form.auctdt)>
			<cfset msg = "Enter an auction date.">
		<cfelseif DateCompare(ParseDateTime(form.auctdt), Now(), "d") LT 0>
			<cfset msg = "Auction date can't be in the past.">
		<cfelse>
			<cfquery name="qUpdLn" datasource="#request.dsn#">
			UPDATE lien SET lnstat = 3, sale_dt = '#DateFormat(ParseDateTime(form.auctdt), "yyyy-mm-dd")#' WHERE lien_id = #url.lien_id#
			</cfquery>
			<cfquery name="qUpdU" datasource="#request.dsn#">
			UPDATE units SET stat = 8 WHERE unit_id = #qRu.unit_id#
			</cfquery>
			<cfset msg = "Auction scheduled.">
		</cfif>
	<cfelseif url.act EQ "plan">
		<cfif qLn.lnstat NEQ 2 AND qLn.lnstat NEQ 3>
			<cfset msg = "Can't put that one on a plan.">
		<cfelse>
			<!--- 7 = still in lien but paying on a plan. dont sell these - GH 4/07 --->
			<cfquery name="qUpdLn" datasource="#request.dsn#">
			UPDATE lien SET lnstat = 7, sale_dt = NULL WHERE lien_id = #url.lien_id#
			</cfquery>
			<cfquery name="qUpdU" datasource="#request.dsn#">
			UPDATE units SET stat = 7 WHERE unit_id = #qRu.unit_id#
			</cfquery>
			<cfset msg = "Payment plan set.">
		</cfif>
	<cfelseif url.act EQ "sale">
		<cfif qLn.lnstat EQ 7>
			<cfset msg = "That rental is on a payment plan. Can't sell.">
		<cfelseif qLn.lnstat NEQ 3>
			<cfset msg = "No auction scheduled for that rental.">
		<cfelseif NOT IsDefined("form.saledt") OR NOT IsDate(form.saledt)>
			<cfset msg = "Enter a sale date.">
		<cfelseif NOT IsDefined("form.saleamt") OR Val(form.saleamt) LTE 0>
			<cfset msg = "Enter the sale amount.">
		<cfelseif DateCompare(ParseDateTime(form.saledt), Now(), "d") GT 0>
			<cfset msg = "Sale date can't be in the future.">
		<cfelseif qLn.sale_dt NEQ "" AND DateCompare(ParseDateTime(form.saledt), qLn.sale_dt, "d") LT 0>
			<cfset msg = "Sale date is before the scheduled auction.">
		<cfelse>
			<cfset saleDt = ParseDateTime(form.saledt)>
			<cfset saleAmt = Round(Val(form.saleamt) * 100) / 100>
			<cfset saleAt = CreateDateTime(Year(saleDt), Month(saleDt), Day(saleDt), Hour(Now()), Minute(Now()), 0)>
			<cfset saleStr = DateFormat(saleAt, "yyyy-mm-dd") & " " & TimeFormat(saleAt, "HH:mm:ss")>
			<cfset left2 = Round((bals[url.rid] - saleAmt) * 100) / 100>

			<cfquery name="qInsSale" datasource="#request.dsn#">
			INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
			VALUES (#url.rid#, 'P', #saleAmt#, '#saleStr#', 'LIEN SALE', '#session.uname#')
			</cfquery>
			<cfquery name="qInsSalePmt" datasource="#request.dsn#">
			INSERT INTO payment (rid, amt, method, chk_no, cc_last4, dt, usr)
			VALUES (#url.rid#, #saleAmt#, 'SALE', NULL, NULL, '#saleStr#', '#session.uname#')
			</cfquery>

			<!--- whatever the sale didnt cover (or overpaid) gets settled right away - GH 4/07 --->
			<cfif left2 LT 0>
				<cfset refAt = DateAdd("d", 3, saleAt)>
				<cfquery name="qInsRef" datasource="#request.dsn#">
				INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
				VALUES (#url.rid#, 'A', #-left2#, '#DateFormat(refAt, "yyyy-mm-dd")# #TimeFormat(refAt, "HH:mm:ss")#', 'refund excess sale proceeds', '#session.uname#')
				</cfquery>
			<cfelseif left2 GT 0>
				<cfset woAt = DateAdd("n", 1, saleAt)>
				<cfquery name="qInsWo" datasource="#request.dsn#">
				INSERT INTO ledger (rid, typ, amt, dt, memo, usr)
				VALUES (#url.rid#, 'A', #-left2#, '#DateFormat(woAt, "yyyy-mm-dd")# #TimeFormat(woAt, "HH:mm:ss")#', 'write off bal after sale', '#session.uname#')
				</cfquery>
			</cfif>

			<cfquery name="qUpdLn" datasource="#request.dsn#">
			UPDATE lien SET lnstat = 4, sale_dt = '#DateFormat(saleDt, "yyyy-mm-dd")#', sale_amt = #saleAmt# WHERE lien_id = #url.lien_id#
			</cfquery>
			<cfquery name="qUpdRent" datasource="#request.dsn#">
			UPDATE rental SET moveout_dt = '#DateFormat(saleDt, "yyyy-mm-dd")#' WHERE rid = #url.rid#
			</cfquery>
			<cfquery name="qUpdU" datasource="#request.dsn#">
			UPDATE units SET stat = 1 WHERE unit_id = #qRu.unit_id#
			</cfquery>
			<cfset msg = "Sale of " & DollarFormat(saleAmt) & " recorded.">
		</cfif>
	<cfelse>
		<cfset msg = "Unknown action.">
	</cfif>

	<cfset session.lienmsg = msg>
	<cflocation url="lien.cfm">
</cfif>

<cfinclude template="hdr.cfm">

<font face="Verdana" size="3"><b>Liens</b></font><br><br>

<cfoutput>
<cfif session.lienmsg NEQ "">
	<font face="Verdana" size="2" color="##CC0000"><b>#session.lienmsg#</b></font><br><br>
	<cfset session.lienmsg = "">
</cfif>
</cfoutput>

<cfloop list="0,1,2,3,7" index="stg">
	<cfset nSec = 0>
	<cfloop query="qRent">
		<cfif StructKeyExists(bals, qRent.rid) AND Val(qRent.lnstat) EQ stg>
			<cfset nSec = nSec + 1>
		</cfif>
	</cfloop>

	<cfoutput>
	<font face="Verdana" size="2"><b>
	<cfif stg EQ 0>Not Yet In Lien
	<cfelseif stg EQ 1>Notice 1 Sent
	<cfelseif stg EQ 2>Notice 2 Sent
	<cfelseif stg EQ 3>Auction Scheduled
	<cfelseif stg EQ 7>Payment Plan</cfif>
	(#nSec#)</b></font><br>
	</cfoutput>

	<cfif nSec GT 0>
	<table border="0" cellpadding="3" cellspacing="0" width="900" style="border:1px solid #99AABB;">
	<tr bgcolor="#E8EEF4">
		<td><b>Rental</b></td>
		<td><b>Tenant</b></td>
		<td><b>Unit</b></td>
		<td><b>Paid Thru</b></td>
		<td align="right"><b>Days Behind</b></td>
		<td align="right"><b>Balance</b></td>
		<td><b>Notice 1</b></td>
		<td><b>Notice 2</b></td>
		<td><b>Sale</b></td>
		<td><b>Action</b></td>
	</tr>
	<cfoutput query="qRent">
	<cfif StructKeyExists(bals, qRent.rid) AND Val(qRent.lnstat) EQ stg>
	<tr <cfif qRent.currentrow MOD 2 EQ 0>bgcolor="##F4F7FA"</cfif>>
		<td><a href="ledger.cfm?rid=#rid#">###rid#</a></td>
		<td>#lname#, #fname#</td>
		<td><font size="1">#FacNm#</font> #unit_no#</td>
		<td>#pdt#</td>
		<td align="right">#behind[rid]#</td>
		<td align="right"><b>#DollarFormat(bals[rid])#</b></td>
		<td>#DateFormat(notice1_dt, "mm/dd/yyyy")#</td>
		<td>#DateFormat(notice2_dt, "mm/dd/yyyy")#</td>
		<td>#DateFormat(sale_dt, "mm/dd/yyyy")#</td>
		<td>
		<cfif stg EQ 0>
			<cfif behind[rid] GTE 31><a href="lien.cfm?act=n1&rid=#rid#">send notice 1</a></cfif>
		<cfelseif stg EQ 1>
			<cfif behind[rid] GTE 52><a href="lien.cfm?act=n2&rid=#rid#&lien_id=#lien_id#">send notice 2</a></cfif>
		<cfelseif stg EQ 2>
			<cfif behind[rid] GTE 80>
			<form action="lien.cfm?act=auct&rid=#rid#&lien_id=#lien_id#" method="post" style="margin:0px;">
			<input type="text" name="auctdt" size="10" value="#DateFormat(DateAdd('d', 14, Now()), 'mm/dd/yyyy')#">
			<input type="submit" value="Schedule Auction">
			</form>
			</cfif>
			<a href="lien.cfm?act=plan&rid=#rid#&lien_id=#lien_id#">put on payment plan</a>
		<cfelseif stg EQ 3>
			<form action="lien.cfm?act=sale&rid=#rid#&lien_id=#lien_id#" method="post" style="margin:0px;">
			<input type="text" name="saledt" size="10" value="#DateFormat(sale_dt, 'mm/dd/yyyy')#">
			$<input type="text" name="saleamt" size="8">
			<input type="submit" value="Record Sale">
			</form>
			<a href="lien.cfm?act=plan&rid=#rid#&lien_id=#lien_id#">put on payment plan</a>
		<cfelseif stg EQ 7>
			&nbsp;
		</cfif>
		</td>
	</tr>
	</cfif>
	</cfoutput>
	</table>
	</cfif>
	<br>
</cfloop>

<cfinclude template="ftr.cfm">
