require"protorx"
require"logger"
require"dbg"
module(...,package.seeall)
local lid
local rests = ""
local login = "IDLE" 
local shkflg = "IDLE" 
local locationflag = false 
local locationfailcnt,FAIL_MAX_CNT = 0,3 
local GPS_OPEN_MIN,GPS_OPEN_MAX = 60,300
local function gettime()
	--[[local t = os.date("*t")
	return string.format("%04d-%02d-%02d %02d:%02d:%02d",t.year,t.month,t.day,t.hour,t.min,t.sec)]]
	return ""
end
local function getphone()
	return nvm.get("RXPHONENUM")
end
local function getadmin()
	return nvm.get("RXADMINNUM")
end
local function getpwd()
	local pwd = string.sub(getadmin(),-6,-1) or ""
	if string.len(pwd) < 6 then pwd = "" end
	return pwd
end
local function getfacid()
	return "YDF"
end
local function getgps()
	local t = {}
	if gps.isfix() then
		t.lng,t.lat = string.match(gps.getgpslocation(),"[EW]*,(%d+%.%d+),[NS]*,(%d+%.%d+)")
	else
		t.lng,t.lat = nvm.get("LNG"),nvm.get("LAT")
	end
	t.lngflg,t.latflg = "E","N"
	t.state = gps.isfix() and 1 or ((t.lng=="" or t.lat=="") and 0 or 2)
	t.cog = gps.getgpscog()
	t.spd = gps.getgpsspd()
	return t
end
local function getstatus()
	return chg.getcharger() and "2" or "255"	
end
local function getcellinfo()
	return sim.getmcc().."."..sim.getmnc().."."..tonumber(net.getlac(),16).."."..tonumber(net.getci(),16)
end
local function getsatsigbat()
	local sig = tonumber(net.getrssi())/3-1
	if sig < 0 then sig = 0 end
	local bat = chg.getvolt()
	if bat >= 4200 then
		bat = 9
	elseif bat >= 4150 then
		bat = 6
	elseif bat >= 3700 then
		bat = 3
	else
		bat = 0
	end
	return gps.getgpssatenum()..sig..bat
end
local tget = {
	["VERSION"] = function() return "W1" end,
	PHONE = getphone,
	ADMIN = getadmin,
	PWD = getpwd,
	FACID = getfacid,
	IMEI = misc.getimei,
	SN = misc.getsn,
	IMSI = sim.getimsi,	
	CELLID = function() return tonumber(net.getci(),16) end,
	LAC = function() return tonumber(net.getlac(),16) end,
	CELLINFO = getcellinfo,
	STATUS = getstatus,
	GPS = getgps,
	SATSIGBAT = getsatsigbat,
	TIME = gettime,
}
local function getf(id)
	assert(tget[id] ~= nil,"getf nil id:" .. id)
	return tget[id]()
end
protorx.reget(getf)
local function qrylocation()
	link.send(lid,protorx.pack(protorx.QRYLOCRSP))
end
function sosloc()
	loc("qry")
end
function keyloc()
	loc("qry")
end
local function getgpsdutycycle()
	local freq = nvm.get("RXRPTFREQ")
	if freq <= GPS_OPEN_MIN then return freq-1,1 end
	local opn = freq/5
	if opn < GPS_OPEN_MIN then opn = GPS_OPEN_MIN end
	if opn > GPS_OPEN_MAX then opn = GPS_OPEN_MAX end
	return freq-opn,opn
end
local function locationopengps()
	if shkflg == "SHK" then
		local _,opn = getgpsdutycycle()
		gpsapp.open(gpsapp.OPEN_TIMERORSUC,{cause="linkrx.locationopengps",val=opn,cb=loc})
		shkflg = "IDLE"
	elseif shkflg == "IDLE" then
		shkflg = "TIMERPASS"
	end
end
function loc(r)
	print("linkrx.loc",r)
	if login ~= "SUC" then return end
	local cls = getgpsdutycycle()
	sys.timer_start(locationopengps,cls*1000)
	if gps.isfix() then
		local t = getgps()
		local move = manage.isrxgpsmove(t.lng,t.lat)
		print("linkrx.loc gps loc",move,locationflag)
		if move or locationflag or r == "qry" then
			if locationfailcnt >= FAIL_MAX_CNT then
				locationfailcnt = 0
				link.disconnect(lid)
				return
			end
			if link.send(lid,protorx.pack(protorx.LOCRPT)) then
				if move then
					manage.setrxlastgps(t.lng,t.lat)
					locationfailcnt = locationfailcnt + 1
				end
				manage.setrxlastlbs(tget["LAC"](),tget["CELLID"]())
			end
		else
		end
	else
		local move = manage.isrxlbsmove(tget["LAC"](),tget["CELLID"]())
		print("linkrx.loc lbs loc",move,locationflag)
		if move or locationflag or r == "qry" then
			if locationfailcnt >= FAIL_MAX_CNT then
				locationfailcnt = 0
				link.disconnect(lid)
				return
			end
			if link.send(lid,protorx.pack(protorx.LOCRPT)) then
				if move then
					manage.setrxlastlbs(tget["LAC"](),tget["CELLID"]())
					locationfailcnt = locationfailcnt + 1
				end
			end
		end
	end
	if locationflag then locationflag = false end
end
local function heart()
	if login ~= "SUC" then return end
	link.send(lid,protorx.pack(protorx.HEART))
end
local function datinactive()
	dbg.restart("RXNODATA")
end
local function checkdatactive()
	sys.timer_start(datinactive,nvm.get("RXHEART")*1000*3+30000) 
end
local reconntimes = 0
local function reconn()
	if reconntimes < 3 then
		reconntimes = reconntimes+1
		link.connect(lid,nvm.get("RXPROT"),nvm.get("RXADDR1"),nvm.get("RXPORT"))
	end
end
local relogintimes = 0
local function relogin()
	if relogintimes < 3 then
		relogintimes = relogintimes+1
		login = "ING"
		link.send(lid,protorx.pack(protorx.LOGIN))
		sys.timer_start(relogin,15000)
	else
		login = "IDLE"
	end
end
local function notify(id,evt,val)
	if id ~= lid then return end
	if evt == "CONNECT" then
		if val == "CONNECT OK" then
			sys.timer_stop(reconn)
			reconntimes = 0
			rests = ""
			login = "ING"
			locationfailcnt = 0			
			if relogintimes < 3 then
				link.send(lid,protorx.pack(protorx.LOGIN))
				sys.timer_start(relogin,15000)
			end
		else
			sys.timer_start(reconn,15000)
		end
	elseif evt == "STATE" then
		if val == "CLOSED" then
			login = "IDLE"
			sys.timer_start(reconn,15000)
		end
	elseif evt == "SEND" then
		if val == "SEND OK" then
			sys.timer_start(heart,nvm.get("RXHEART")*1000)
		end
	elseif evt == "DISCONNECT" then
		login = "IDLE"
		sys.timer_stop(relogin)
		sys.timer_start(reconn,15000)
	end
	if string.match(val,"ERROR") then
		link.disconnect(lid)
	end
end
local function loginrsp(packet)
	if packet.response == "OK" and login == "ING" then
		sys.timer_stop(relogin)
		relogintimes = 0
		login = "SUC"
		loc("login")		
	end
end
local function updfreq(freq)
	if freq <= GPS_OPEN_MIN then
		gpsapp.open(gpsapp.OPEN_DEFAULT,{cause="RXFREQ"})
	else
		gpsapp.close(gpsapp.OPEN_DEFAULT,{cause="RXFREQ"})
	end
	loc("updfreq")
end
local function set(packet)
	local result = 0
	local function setfreq()
		local v = tonumber(packet.val)
		if v < 15 then return 0 end
		if nvm.get("RXRPTFREQ") ~= v then
			nvm.set("RXRPTFREQ",v,true)
			updfreq(v)
		end
		return 1
	end
	local function setheart()
		local v = tonumber(packet.val)
		if v < 15 then return 0 end
		if nvm.get("RXHEART") ~= v then
			nvm.set("RXHEART",v,true)
			sys.timer_start(heart,v*1000)
		end
		return 1
	end
	local function setuser()
		local v = packet.val
		if nvm.get("RXADMINNUM") ~= v then
			nvm.set("RXADMINNUM",v,true)			
		end
		return 1
	end
	local procer = {
		[protorx.PARAFREQ] = setfreq,
		[protorx.PARAHEART] = setheart,
		[protorx.PARAUSER] = setuser,
	}
	if procer[packet.typ] then
		result = procer[packet.typ]()
	end	
	link.send(lid,protorx.pack(protorx.SETRSP,packet.typ,result))
end
local function locrptrsp()
	manage.updrxgpsinf()
end
local function qryloc()
	gpsapp.open(gpsapp.OPEN_TIMERORSUC,{cause="linkrx.qryloc",val=120,cb=qrylocation})
end
local function restart()
	dbg.restart("RXSVR")
end
local function guardon()
	link.send(lid,protorx.pack(protorx.GUARDONRSP,1))
end
local function guardoff()
	link.send(lid,protorx.pack(protorx.GUARDOFFRSP,1))
end
local function heartrsp()
end
local function qrypara(packet)
	local result = packet.typ
	local function getfreq()
		return protorx.PARAFREQ.."="..nvm.get("RXRPTFREQ")
	end
	local function getheart()
		return protorx.PARAHEART.."="..nvm.get("RXHEART")
	end
	local function getuser()
		return protorx.PARAUSER.."="..nvm.get("RXADMINNUM")
	end
	local procer = {
		[protorx.PARAFREQ] = getfreq,
		[protorx.PARAHEART] = getheart,
		[protorx.PARAUSER] = getuser,
	}
	if procer[packet.typ] then
		result = procer[packet.typ]()
	end	
	link.send(lid,protorx.pack(protorx.QRYPARARSP,result))
end
local cmds = {
	[protorx.LOGINRSP] = loginrsp,
	[protorx.SET] = set,
	[protorx.LOCRPTRSP] = locrptrsp,
	[protorx.QRYLOC] = qryloc,
	[protorx.RESTART] = restart,
	[protorx.GUARDON] = guardon,
	[protorx.GUARDOFF] = guardoff,
	[protorx.HEARTRSP] = heartrsp,
	[protorx.QRYPARA] = qrypara,
}
local function recv(id,data)
	checkdatactive()
	locationfailcnt = 0
	rests = rests .. data
	local _,pos = string.find(rests,"]")
	while pos do
		data = string.sub(rests,1,pos)
		rests = string.sub(rests,pos+1,-1)
		local packet = protorx.unpack(data)
		if packet and packet.id and cmds[packet.id] then
			cmds[packet.id](packet)
		end
		_,pos = string.find(rests,"]")
	end
end
local function proc(id,data)
	if id == "DEV_WAKE_IND" then
	elseif id == "DEV_CHG_IND" then
	elseif id == "DEV_SHK_IND" then
		if shkflg == "IDLE" then
			shkflg = "SHK"
		elseif shkflg == "TIMERPASS" then
			shkflg = "SHK"
			if gps.isfix() then
				locationflag = true
				loc("TIMERPASS")
			else
				locationopengps()
			end
		end
	elseif id == "CCAPP_CONNECT" then
		sys.timer_stop(datinactive)
	elseif id == "CCAPP_DISCONNECT" then
		reconntimes = 0
		link.connect(lid,nvm.get("RXPROT"),nvm.get("RXADDR1"),nvm.get("RXPORT"))
		checkdatactive()		
	elseif id == gps.GPS_STATE_IND then
		print("linkrx.gpsstatind",id,data)
		if data == gps.GPS_LOCATION_SUC_EVT and not firstgps then
			firstgps = true
			loc("firstgps")
		end
	elseif id == "NET_CELL_CHANGED" and gps.isfix() then
		manage.setrxlastlbs(tget["LAC"](),tget["CELLID"]())
	end
	return true
end
sys.regapp(proc,"DEV_WAKE_IND","DEV_SHK_IND","DEV_CHG_IND","CCAPP_CONNECT","CCAPP_DISCONNECT",gps.GPS_STATE_IND,"NET_CELL_CHANGED","DW_SMS","FIRST_GPS")
net.startquerytimer()
lid = link.open(notify,recv)
link.connect(lid,nvm.get("RXPROT"),nvm.get("RXADDR1"),nvm.get("RXPORT"))
checkdatactive()
if nvm.get("RXRPTFREQ") <= GPS_OPEN_MIN then
	gpsapp.open(gpsapp.OPEN_DEFAULT,{cause="RXFREQ"})
end
