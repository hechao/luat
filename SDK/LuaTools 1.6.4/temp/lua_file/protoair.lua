require"logger"
local lpack = require"pack"
module(...,package.seeall)
local slen,sbyte,ssub,sgsub,schar,srep,smatch,sgmatch = string.len,string.byte,string.sub,string.gsub,string.char,string.rep,string.match,string.gmatch
SVR,SVR1 = 0,1
LOGIN,GPS,LBS1,LBS2,HEART,QUERY,DW_QUERY = 0,1,2,3,4,5,0
COMMON,SYNC,SENDSMS,DIAL,QUERYRSP = 0,1,2,5,6
LOGIN1,SETRSP,HEART1 = 0,1,2
SET,COMMON1,HEARTRSP = 0,1,2
RELAYON,RELAYOFF,QRYLOC,RPTFREQ = 0,1,2,3
local PROTOVERSION = 0
local serial = 0
local imei 
local log = logger.new("PROTOAIR","BIN2")
local get
local function bcd(d,n)
	local l = slen(d or "")
	local num
	local t = {}
	for i=1,l,2 do
		num = tonumber(ssub(d,i,i+1),16)
		if i == l then
			num = 0xf0+num
		else
			num = (num%0x10)*0x10 + num/0x10
		end
		table.insert(t,num)
	end
	local s = schar(_G.unpack(t))
	l = slen(s)
	if l < n then
		s = s .. srep("\255",n-l)
	elseif l > n then
		s = ssub(s,1,n)
	end
	return s
end
local function unbcd(d)
	local byte,v1,v2
	local t = {}
	for i=1,slen(d) do
		byte = sbyte(d,i)
		v1,v2 = bit.band(byte,0x0f),bit.band(bit.rshift(byte,4),0x0f)
		if v1 == 0x0f then break end
		table.insert(t,v1)
		if v2 == 0x0f then break end
		table.insert(t,v2)
	end
	return table.concat(t)
end
local function enlnla(s)
	local v1,v2 = smatch(s,"(%d+)%.(%d+)")
	if slen(v1) < 3 then v1 = srep("0",3-slen(v1)) .. v1 end
	return bcd(v1..v2,5)
end
local function enstat()
	local stat = get("STATUS")
	local rssi = get("RSSI")
	local gpstat = get("GPSTAT")
	local satenum = gpstat.satenum
	local n1 = stat.shake + stat.charger*2 + stat.acc*4 + stat.gps*8 + stat.sleep*16
	rssi = rssi > 31 and 31 or rssi
	satenum = satenum > 7 and 7 or satenum
	local n2 = rssi + satenum*32
	return lpack.pack(">bbH",n1,n2,stat.volt)
end
local function encellinfo()
	local info,ret,t,lac,ci,rssi,k,v,m,n,cntrssi = get("CELLINFO"),"",{}
	print("encellinfo",info)
	for lac,ci,rssi in sgmatch(info,"(%d+)%.(%d+).(%d+);") do
		lac,ci,rssi = tonumber(lac),tonumber(ci),(tonumber(rssi) > 31) and 31 or tonumber(rssi)
		local handle = nil
		for k,v in pairs(t) do
			if v.lac == lac then
				if #v.rssici < 8 then
					table.insert(v.rssici,{rssi=rssi,ci=ci})
				end
				handle = true
				break
			end
		end
		if not handle then
			table.insert(t,{lac=lac,rssici={{rssi=rssi,ci=ci}}})
		end
	end
	for k,v in pairs(t) do
		ret = ret .. lpack.pack(">H",v.lac)
		for m,n in pairs(v.rssici) do
			cntrssi = bit.bor(bit.lshift(((m == 1) and (#v.rssici-1) or 0),5),n.rssi)
			ret = ret .. lpack.pack(">bH",cntrssi,n.ci)
		end
	end
	return ret
end
function pack(svr,id,...)
	if not imei then imei = bcd(get("IMEI"),8) end
	local head = (svr == SVR) and lpack.pack("Abb",imei,serial,id) or lpack.pack("bb",1,id)
	local function login()
		local ver = bcd(sgsub(get("VERSION"),"%.",""),2)
		local imsi,iccid,sn = bcd(get("IMSI"),8),bcd(get("ICCID"),10),get("SN")
		return lpack.pack("bAAApA",PROTOVERSION,ver,imsi,iccid,sn,get("FNCPARA"))
	end
	local function gps()
		local t = get("GPS")
		lng = enlnla(t.lng)
		lat = enlnla(t.lat)
		return lpack.pack(">AAHbA",lng,lat,t.cog,t.spd,enstat())
	end
	local function lbs1()
		local ci,lac = get("CELLID"),get("LAC")
		return lpack.pack(">IHA",ci,lac,enstat())
	end
	local function lbs2()
		return lpack.pack("AA",encellinfo(),enstat())
	end
	local function heart()
		return lpack.pack("A",enstat())
	end
	local function query(typ)
		return lpack.pack("b",typ)
	end
	local function login1()
		return lpack.pack("A",imei)
	end
	local function setrsp(typ,result)
		return lpack.pack("bb",typ,result)
	end
	local function empty()
		return ""
	end
	local procer = {}
	procer[SVR] = {
		[LOGIN] = login,
		[GPS] = gps,
		[LBS1] = lbs1,
		[LBS2] = lbs2,
		[HEART] = heart,
		[QUERY] = query,
	}
	procer[SVR1] = {
		[LOGIN1] = login1,
		[SETRSP] = setrsp,
		[HEART1] = empty,
	}
	local s = head .. procer[svr][id](...)
	s = lpack.pack("p",s)
	s = sgsub(s,"\219","\219\221") 
	s = sgsub(s,"\192","\219\220") 
	s = s .. "\192"
	log:write(0,s)
	return s
end
function unpack(svr,s)
	log:write(1,s)
	local packet = {}
	local function respcmn(d)
		if slen(d) == 0 then return end
		local cmd = sbyte(d)+1
		local t = {
			"ERROR","OK","RESTART","BUSY","UNLOGGED","NOTFOUND","NORESULT"
		}
		if not t[cmd] then return end
		packet.response = t[cmd]
		return true
	end
	local function sync(d)
		if slen(d) == 0 then return end
		packet.relay = bit.band(sbyte(d),0x01)
		if slen(d) >= 3 then
			_,packet.rptfreq = lpack.unpack(ssub(d,2,3),">H")
		end
		return true
	end
	local function pushsms(d)
		if slen(d) == 0 then return end
		local numcnt,i = sbyte(d)
		if numcnt*6+1 >= slen(d) then return end
		packet.num = {}
		for i=1,numcnt do
			local n = unbcd(ssub(d,2+(i-1)*6,7+(i-1)*6))
			if n and slen(n) > 0 then
				table.insert(packet.num,n)
			end
		end
		local t = {"7BIT","UCS2"}
		local typ = sbyte(d,numcnt*6+2)+1
		if not t[typ] then return end
		packet.coding = t[typ]
		packet.data = ssub(d,numcnt*6+3,-1)
		if not packet.data or slen(packet.data) <= 0 then return end
		return true
	end
	local function dial(d)
		if slen(d) == 0 then return end
		local numcnt,i = sbyte(d)
		if numcnt*6 >= slen(d) then return end
		packet.num = {}
		for i=1,numcnt do
			local n = unbcd(ssub(d,2+(i-1)*6,7+(i-1)*6))
			if n and slen(n) > 0 then
				table.insert(packet.num,n)
			end
		end
		return true
	end
	local function queryrsp(d)
		if slen(d) == 0 then return end
		local function dwrsp(d)
			if slen(d) == 0 then return end
			local t = {"7BIT","UCS2"}
			local typ = sbyte(d)+1
			if not t[typ] then return end
			packet.coding = t[typ]
			packet.data = ssub(d,2,-1)
			if not packet.data or slen(packet.data) <= 0 then return end
			return true
		end
		local proc = {
			[DW_QUERY] = dwrsp,
		}
		local typ = sbyte(d)
		if not proc[typ] then print("protoair.unpack:unknwon queryrsp",typ) return end
		packet.typ = typ
		return proc[typ](ssub(d,2,-1)) and packet or nil
	end
	local function set(d)
		if slen(d) > 0 then			
			local function dummy(par)
				return slen(par) == 0
			end
			local function rptfreq(par)
				if slen(par) ~= 2 then return end
				_,packet.freq = lpack.unpack(par,">H")
				return true
			end
			local proc =
			{
				[RELAYON] = dummy,
				[RELAYOFF] = dummy,
				[QRYLOC] = dummy,
				[RPTFREQ] = rptfreq,
			}
			packet.cmd = sbyte(d)
			if not proc[sbyte(d)] then print("protoair.unpack:unknwon set",sbyte(d)) return end			
			return proc[sbyte(d)](ssub(d,2,-1)) and packet or nil
		end
	end
	local function empty()
		return true
	end
	local procer = {}
	procer[SVR] = {
		[COMMON] = respcmn,
		[SYNC] = sync,
		[SENDSMS] = pushsms,
		[DIAL] = dial,
		[QUERYRSP] = queryrsp,
	}
	procer[SVR1] = {		
		[SET] = set,
		[COMMON1] = respcmn,
		[HEARTRSP] = empty,
	}
	s = sgsub(s,"\219\220","\192") 
	s = sgsub(s,"\219\221","\219") 
	if sbyte(s,-1,-1) ~= 0xc0 then print("protoair.unpack:invalid end") return end
	local ididx,len = svr==SVR and 3 or 2,sbyte(s,1)
	local id = sbyte(s,ididx)
	if len ~= (slen(s)-2) then print("protoair.unpack:invalid len") return end
	if not procer[svr][id] then print("protoair.unpack:unknwon id",id) return end
	s = ssub(s,ididx+1,-2)
	packet.id = id
	return procer[svr][id](s) and packet or nil
end
function reget(id)
	get = id
end
