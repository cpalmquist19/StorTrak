<!--- left nav - GH 2006 --->
<table width="100%" border="0" cellpadding="4" cellspacing="0">
<tr><td><a href="index.cfm">Dashboard</a></td></tr>
<tr><td><a href="unitmap.cfm">Unit Map</a></td></tr>
<tr><td><a href="movein.cfm">Move In</a></td></tr>
<tr><td><a href="ledger.cfm">Ledger</a></td></tr>
<tr><td><a href="pmt.cfm">Take Payment</a></td></tr>
<tr><td><a href="moveout.cfm">Move Out</a></td></tr>
<tr><td><a href="lien.cfm">Liens</a></td></tr>
<tr><td><a href="rates.cfm">Rates</a></td></tr>
<tr><td><font face="Verdana" size="1" color="#666666"><b>REPORTS</b></font></td></tr>
<tr><td>&nbsp;&nbsp;<a href="rpt_occ.cfm">Occupancy</a></td></tr>
<tr><td>&nbsp;&nbsp;<a href="rpt_dlq.cfm">Delinquency</a></td></tr>
<tr><td>&nbsp;&nbsp;<a href="rpt_eod.cfm">End of Day</a></td></tr>
<cfif session.lvl EQ 9>
<tr><td><a href="settings.cfm">Settings</a></td></tr>
</cfif>
<tr><td><a href="logout.cfm">Logout</a></td></tr>
</table>
