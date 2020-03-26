module(...,package.seeall)
RELAYFNC,QRYLOCFNC,RPTFREQFNC = false,true,true
local inf = {}
local function init()
	setgpsfilterdist(30)
	inf.lastlong,inf.lastlati,inf.lastlac,inf.lastci = nil
	inf.rxlastlong,inf.rxlastlati,inf.rxlastlac,inf.rxlastci,inf.rxtmplong,inf.rxtmplati = nvm.get("LNG"),nvm.get("LAT")
end
function setgpsfilterdist(dist)
	print("setgpsfilterdist",dist)
	inf.gpsfilterdist = dist
end
function setlastgps(long,lati)
	inf.lastlong = long
	inf.lastlati = lati
end
function isgpsmove(long,lati)
	if not inf.lastlong or inf.lastlong == "" or not inf.lastlati or inf.lastlati == "" then return true end
	local dist = gps.diffofloc(lati,long,inf.lastlati,inf.lastlong)
	print("isgpsmove",lati,long,inf.lastlati,inf.lastlong,dist,inf.gpsfilterdist)
	return dist >= inf.gpsfilterdist*inf.gpsfilterdist or dist < 0
end
function setlastlbs(lac,ci)
	inf.lastlac = lac
	inf.lastci = ci
end
function islbsmove(lac,ci)
	return lac ~= inf.lastlac or ci ~= inf.lastci
end
function setrxlastgps(long,lati)
	inf.rxtmplong = long
	inf.rxtmplati = lati
end
function isrxgpsmove(long,lati)
	if not inf.rxlastlong or inf.rxlastlong == "" or not inf.rxlastlati or inf.rxlastlati == "" then return true end
	local dist = gps.diffofloc(lati,long,inf.rxlastlati,inf.rxlastlong)
	print("isrxgpsmove",lati,long,inf.rxlastlati,inf.rxlastlong,dist,inf.gpsfilterdist)
	return dist >= inf.gpsfilterdist*inf.gpsfilterdist or dist < 0
end
function setrxlastlbs(lac,ci)
	inf.rxlastlac = lac
	inf.rxlastci = ci
end
function isrxlbsmove(lac,ci)
	return lac ~= inf.rxlastlac or ci ~= inf.rxlastci
end
function updrxgpsinf(lng,lat)
	inf.rxlastlong,inf.rxlastlati = lng or (inf.rxtmplong or ""),lat or (inf.rxtmplati or "")
	if nvm.get("LNG") ~= inf.rxlastlong or nvm.get("LAT") ~= inf.rxlastlati then
		nvm.set("LNG",inf.rxlastlong,false)
		nvm.set("LAT",inf.rxlastlati,false)
		nvm.flush()
	end
end
init()
