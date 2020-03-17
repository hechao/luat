require"protoair"
require"logger"
require"sms"
require"dbg"
require"ccapp"
module(...,package.seeall)
local prot,server,port,lid = "UDP","180.97.81.180",12392
local shkcnt = 0
local shkflg = "IDLE" 
local locationflag = false 
local login = "IDLE" 
local locationfailcnt,FAIL_MAX_CNT = 0,3 
local firstgps
local GPS_OPEN_MIN,GPS_OPEN_MAX = 60,300
local HEART_BEAT = 300
local function getstatus()
	local t = {}
	t.shake = (shkcnt > 0) and 1 or 0
	shkcnt = 0
	t.charger = chg.getcharger() and 1 or 0
	t.acc = acc.getflag() and 1 or 0
	t.gps = gps.isopen() and 1 or 0
	t.sleep = pm.isleep() and 1 or 0
	t.volt = chg.getvolt()
	return t
end
local function getgps()
	local t = {}
	print("getgps:",gps.getgpslocation(),gps.getgpscog(),gps.getgpsspd())
	t.lng,t.lat = string.match(gps.getgpslocation(),"[EW]*,(%d+%.%d+),[NS]*,(%d+%.%d+)")
	t.cog = gps.getgpscog()
	t.spd = gps.getgpsspd()
	return t
end
local function getgpstat()
	local t = {}
	t.satenum = gps.getgpssatenum()
	return t
end
local function getfncpara()
	local n1 = (manage.RELAYFNC and 1 or 0) + (manage.QRYLOCFNC and 1 or 0)*2 + (manage.RPTFREQFNC and 1 or 0)*4	
	local n2,n3,n4,n5,n6,n7,n8 = 0,0,0,0,0,0,0
	local p = pack.pack(">bH",(manage.RELAYFNC and nvm.get("RELAY") or 0),(manage.RPTFREQFNC and nvm.get("RPTFREQ") or 0))
	return pack.pack("bbbbbbbbA",n1,n2,n3,n4,n5,n6,n7,n8,p)
end
local tget = {
	["VERSION"] = function() return _G.VERSION end,
	IMEI = misc.getimei,
	SN = misc.getsn,
	IMSI = sim.getimsi,
	ICCID = sim.geticcid,
	RSSI = net.getrssi,
	CELLID = function() return tonumber(net.getci(),16) end,
	LAC = function() return tonumber(net.getlac(),16) end,
	CELLINFO = net.getcellinfo,
	STATUS = getstatus,
	GPS = getgps,
	GPSTAT = getgpstat,
	FNCPARA = getfncpara,
}
local function getf(id)
	assert(tget[id] ~= nil,"getf nil id:" .. id)
	return tget[id]()
end
protoair.reget(getf)
local function qrylocation()
	location("qry")
end
function sosloc()
	qrylocation()
end
function keyloc()
	qrylocation()
end
local function getgpsdutycycle()
	local freq = nvm.get("RPTFREQ")
	if freq <= GPS_OPEN_MIN then return freq-1,1 end
	local opn = freq/5
	if opn < GPS_OPEN_MIN then opn = GPS_OPEN_MIN end
	if opn > GPS_OPEN_MAX then opn = GPS_OPEN_MAX end
	return freq-opn,opn
end
local function locationopengps()
	if shkflg == "SHK" then
		local _,opn = getgpsdutycycle()
		gpsapp.open(gpsapp.OPEN_TIMERORSUC,{cause="linkair.locationopengps",val=opn,cb=location})
		shkflg = "IDLE"
	elseif shkflg == "IDLE" then
		shkflg = "TIMERPASS"
	end
end
function location(r)
	if login ~= "SUC" then return end
	local cls = getgpsdutycycle()
	sys.timer_start(locationopengps,cls*1000)
	if gps.isfix() then
		local t = getgps()
		local move = manage.isgpsmove(t.lng,t.lat)
		print("gps location",move,locationflag)
		if move or locationflag or r == "qry" then
			if locationfailcnt >= FAIL_MAX_CNT then
				locationfailcnt = 0
				link.disconnect(lid)
				return
			end
			if link.send(lid,protoair.pack(protoair.SVR,(move or r == "qry") and protoair.GPS or protoair.HEART)) then
				if move then
					manage.setlastgps(t.lng,t.lat)
					locationfailcnt = locationfailcnt + 1
				end
				manage.setlastlbs(tget["LAC"](),tget["CELLID"]())
			end
		else
		end
	else
		local move = manage.islbsmove(tget["LAC"](),tget["CELLID"]())
		print("lbs location",move,locationflag)
		if move or locationflag or r == "qry" then
			if locationfailcnt >= FAIL_MAX_CNT then
				locationfailcnt = 0
				link.disconnect(lid)
				return
			end
			if link.send(lid,protoair.pack(protoair.SVR,move and protoair.LBS1 or protoair.HEART)) then
				if move then
					manage.setlastlbs(tget["LAC"](),tget["CELLID"]())
					locationfailcnt = locationfailcnt + 1
				end
			end
		end
	end
	if locationflag then locationflag = false end
end
local function heartbeat()
	if login ~= "SUC" then return end
	link.send(lid,protoair.pack(protoair.SVR,protoair.HEART))
end
local tsmssendnum = {}
local function query(typ,num)
	if not (login == "SUC" and link.send(lid,protoair.pack(protoair.SVR,protoair.QUERY,typ))) then
		sms.send(num,common.binstohexs(common.gb2312toucs2be("Õ¯¬Á∑±√¶£¨«Î…‘∫Ó‘Ÿ ‘£°")))
	else
		table.insert(tsmssendnum,num)
	end
end
local levt,lval,lerrevt,lerrval = "","","",""
local function datinactive()
	dbg.restart("AIRNODATA" .. ((levt ~= nil) and (",EVT=" .. levt) or "") .. ((lval ~= nil) and (",VAL=" .. lval) or "").. ((lerrevt ~= nil) and (",ERREVT=" .. lerrevt) or "") .. ((lerrval ~= nil) and (",ERRVAL=" .. lerrval) or ""))
end
local function checkdatactive()
	sys.timer_start(datinactive,HEART_BEAT*1000*3+30000) 
end
local rests = ""
local reconntimes = 0
local function reconn()
	if reconntimes < 3 then
		reconntimes = reconntimes+1
		link.connect(lid,prot,server,port)
	end
end
local relogintimes = 0
local function relogin()
	if relogintimes < 3 then
		relogintimes = relogintimes+1
		login = "ING"
		link.send(lid,protoair.pack(protoair.SVR,protoair.LOGIN))
		sys.timer_start(relogin,5000)
	else
		relogintimes = 0
		login = "IDLE"
	end
end
local function notify(id,evt,val)
	print("linkair notify",id,evt,val)
	if id ~= lid then return end
	levt,lval = evt,val
	if evt == "CONNECT" then
		if val == "CONNECT OK" then
			sys.timer_stop(reconn)
			reconntimes = 0
			rests = ""
			login = "ING"
			locationfailcnt = 0
			link.send(lid,protoair.pack(protoair.SVR,protoair.LOGIN))
			sys.timer_start(relogin,5000)
		else
			sys.timer_start(reconn,5000)
		end
	elseif evt == "STATE" then
		if val == "CLOSED" then
			login = "IDLE"
			sys.timer_start(reconn,5000)
		end
	elseif evt == "SEND" then
		if val == "SEND OK" then
			sys.timer_start(heartbeat,HEART_BEAT*1000)
		else
			lerrevt,lerrval = evt,val
		end
	elseif evt == "DISCONNECT" then
		login = "IDLE"
		relogintimes = 0
		sys.timer_stop(relogin)
		sys.timer_start(reconn,5000)
	end
	if string.match(val,"ERROR") then
		lerrevt,lerrval = evt,val
		link.disconnect(lid)
	end
end
local function commonresponse(packet)
	if packet.response == "RESTART" then
		dbg.restart("AIRSVR")
	elseif packet.response == "OK" and login == "ING" then
		sys.timer_stop(relogin)
		relogintimes = 0
		login = "SUC"
		location("login")
		sys.timer_start(heartbeat,HEART_BEAT*1000)
	elseif packet.response == "UNLOGGED" then
		link.disconnect(lid)
	end
end
local function updfreq(freq)
	if freq <= GPS_OPEN_MIN then
		gpsapp.open(gpsapp.OPEN_DEFAULT,{cause="FREQ"})
	else
		gpsapp.close(gpsapp.OPEN_DEFAULT,{cause="FREQ"})
	end
	location("updfreq")
end
local function sync(packet)
	if manage.RELAYFNC and packet.relay then manage.setrelay(packet.relay) end
	if manage.RPTFREQFNC and packet.rptfreq and nvm.get("RPTFREQ") ~= packet.freq then
		nvm.set("RPTFREQ",packet.rptfreq,true)
		updfreq(packet.rptfreq)
	end
end
local function sendsms(packet)
	if packet.coding == "UCS2" then
		while #packet.num > 0 do
			sms.send(table.remove(packet.num,1),common.binstohexs(packet.data))
		end
	end
end
local function queryrsp(packet)
	if packet.typ == protoair.DW_QUERY then
		if packet.coding == "UCS2" then
			while #tsmssendnum > 0 do
				sms.send(table.remove(tsmssendnum,1),common.binstohexs(packet.data))
			end
		end
	end
end
local function dial(packet)
	while #packet.num > 0 do
		sys.dispatch("CCAPP_ADD_NUM",table.remove(packet.num,1))
	end
	sys.dispatch("CCAPP_DIAL_NUM")
end
local cmds = {
	[protoair.COMMON] = commonresponse,
	[protoair.SYNC] = sync,
	[protoair.SENDSMS] = sendsms,
	[protoair.DIAL] = dial,
	[protoair.QUERYRSP] = queryrsp,
}
local function recv(id,data)
	checkdatactive()
	locationfailcnt = 0
	rests = rests .. data
	local _,pos = string.find(rests,"\192")
	while pos do
		data = string.sub(rests,1,pos)
		rests = string.sub(rests,pos+1,-1)
		local packet = protoair.unpack(protoair.SVR,data)
		if packet and packet.id and cmds[packet.id] then
			cmds[packet.id](packet)
		end
		_,pos = string.find(rests,"\192")
	end
end
net.startquerytimer()
lid = link.open(notify,recv)
link.connect(lid,prot,server,port)
checkdatactive()
if nvm.get("RPTFREQ") <= GPS_OPEN_MIN then
	gpsapp.open(gpsapp.OPEN_DEFAULT,{cause="FREQ"})
end
local prot1,server1,port1,lid1 = "TCP","180.97.81.180",12394
local rests1,login1 = "","IDLE"
local HEART = 900000
local reconntimes1 = 0
local function reconn1()
	if reconntimes1 < 3 then
		reconntimes1 = reconntimes1+1
		link.connect(lid1,prot1,server1,port1)
	else
		reconntimes1 = 0
		sys.timer_start(reconn1,300000)
	end
end
local relogintimes1 = 0
local function relogin1()
	if relogintimes1 < 3 then
		relogintimes1 = relogintimes1+1
		login1 = "ING"
		link.send(lid1,protoair.pack(protoair.SVR1,protoair.LOGIN1))
		sys.timer_start(relogin1,5000)
	else
		relogintimes1 = 0
		login1 = "IDLE"
	end
end
local function heart()
	link.send(lid1,protoair.pack(protoair.SVR1,protoair.HEART1))
	sys.timer_start(link.disconnect,10000,lid1,"r1")
end
local function notify1(id,evt,val)
	if id ~= lid1 then return end
	if evt == "CONNECT" then
		if val == "CONNECT OK" then
			sys.timer_stop(reconn1)
			reconntimes1 = 0
			rests1 = ""
			login1 = "ING"
			link.send(lid1,protoair.pack(protoair.SVR1,protoair.LOGIN1))
		else
			sys.timer_start(reconn1,5000)
		end
	elseif evt == "SEND" then
		if login1 == "ING" then
			sys.timer_start(relogin1,5000)
		end
		sys.timer_start(heart,HEART)
	elseif evt == "STATE" then
		if val == "CLOSED" then
			login1 = "IDLE"
			sys.timer_start(reconn1,5000)
		end
	elseif evt == "DISCONNECT" then
		login1 = "IDLE"
		relogintimes1 = 0
		sys.timer_stop(relogin1)
		sys.timer_start(reconn1,5000)
	end
	if string.match(val,"ERROR") then
		link.disconnect(lid1)
	end
end
local function commonresponse1(packet)
	if packet.response == "RESTART" then
		dbg.restart("AIRSVR1")
	elseif packet.response == "OK" and login1 == "ING" then
		sys.timer_stop(relogin1)
		relogintimes1 = 0
		login1 = "SUC"		
	elseif packet.response == "UNLOGGED" then
		link.disconnect(lid1)
	end
end
local function relay(packet)
	if not manage.RELAYFNC then return 0 end
	manage.setrelay(packet.cmd-protoair.RELAYON)
	return 1		
end
local function qrylocrsp(packet)
	if not manage.QRYLOCFNC then return 0 end		
	if not gps.isfix() then
		link.send(lid,protoair.pack(protoair.SVR,protoair.LBS1))
	end
	gpsapp.open(gpsapp.OPEN_TIMERORSUC,{cause="linkair.qrylocrsp",val=120,cb=qrylocation})
	return 1
end
local function rptfreq(packet)
	if not manage.RPTFREQFNC then return 0 end		
	if nvm.get("RPTFREQ") ~= packet.freq then
		print("rptfreq",packet.freq)
		nvm.set("RPTFREQ",packet.freq,true)
		updfreq(packet.freq)
	end
	return 1		
end
local function set(packet)
	local result = 0	
	local procer = {
		[protoair.RELAYON] = relay,
		[protoair.RELAYOFF] = relay,
		[protoair.QRYLOC] = qrylocrsp,
		[protoair.RPTFREQ] = rptfreq,
	}
	if procer[packet.cmd] then
		result = procer[packet.cmd](packet)
	end	
	link.send(lid1,protoair.pack(protoair.SVR1,protoair.SETRSP,packet.cmd,result))
end
local function heartrsp(packet)
	sys.timer_stop(link.disconnect,lid1,"r1")
end
local cmds1 = {
	[protoair.COMMON1] = commonresponse1,
	[protoair.SET] = set,
	[protoair.HEARTRSP] = heartrsp,
}
local function recv1(id,data)
	rests1 = rests1 .. data
	local _,pos = string.find(rests1,"\192")
	while pos do
		data = string.sub(rests1,1,pos)
		rests1 = string.sub(rests1,pos+1,-1)
		local packet = protoair.unpack(protoair.SVR1,data)
		if packet and packet.id and cmds1[packet.id] then
			cmds1[packet.id](packet)
		end
		_,pos = string.find(rests1,"\192")
	end
end
lid1 = link.open(notify1,recv1)
link.connect(lid1,prot1,server1,port1)
local function proc(id,data)
	if id == "DEV_WAKE_IND" then
		locationflag = true		
	elseif id == "DEV_CHG_IND" then
		locationflag = true
	elseif id == "DEV_SHK_IND" then
		locationflag = true
		shkcnt = shkcnt + 1		
		if shkflg == "IDLE" then
			shkflg = "SHK"
		elseif shkflg == "TIMERPASS" then
			shkflg = "SHK"
			link.send(lid,protoair.pack(protoair.SVR,protoair.LBS1))
			locationopengps()
		end
	elseif id == "CCAPP_CONNECT" then
		sys.timer_stop(datinactive)
	elseif id == "CCAPP_DISCONNECT" then
		reconntimes = 0
		link.connect(lid,prot,server,port)
		checkdatactive()
		reconntimes1 = 0
		link.connect(lid1,prot1,server1,port1)
	elseif id == gps.GPS_STATE_IND then
		print("linkair.gpsstatind",id,data)
		if data == gps.GPS_LOCATION_SUC_EVT and not firstgps then
			firstgps = true
			location("firstgps")
		end
	elseif id == "NET_CELL_CHANGED" and gps.isfix() then
		manage.setlastlbs(tget["LAC"](),tget["CELLID"]())
	elseif id == "DW_SMS" then
		if data and string.len(data) > 0 then
			query(protoair.DW_QUERY,data)
		end
	elseif id == "SET_FREQ_SMS" then
		rptfreq({freq = data})
	end
	return true
end
sys.regapp(proc,"DEV_WAKE_IND","DEV_SHK_IND","DEV_CHG_IND","CCAPP_CONNECT","CCAPP_DISCONNECT",gps.GPS_STATE_IND,"NET_CELL_CHANGED","DW_SMS","SET_FREQ_SMS")
