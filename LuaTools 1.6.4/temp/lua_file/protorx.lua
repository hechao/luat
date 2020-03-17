require"logger"
local lpack = require"pack"
module(...,package.seeall)
local slen,sbyte,ssub,sgsub,schar,srep,smatch,sgmatch,sfind = string.len,string.byte,string.sub,string.gsub,string.char,string.rep,string.match,string.gmatch,string.find
LOGIN,LOCRPT,HEART,SETRSP,QRYLOCRSP,QRYPARARSP,GUARDONRSP,GUARDOFFRSP = "T1","T3","T0","T2","T10","T14","T12","T13"
LOGINRSP,SET,LOCRPTRSP,QRYLOC,HEARTRSP,QRYPARA,RESTART,GUARDON,GUARDOFF = "S1","S2","S3","S10","S0","S14","S11","S12","S13"
PARAFREQ,PARAHEART,PARAUSER = "FREQ","PULSE","USER"
local log = logger.new("PROTORX","BIN2")
local get
function pack(id,...)
	local head,tail = "["..get("TIME")..",0,W1,"..get("SN")..","..id..",", "]"
	local function login()
		return get("PHONE")..","..get("ADMIN")..","..get("PWD")..",11,"..get("IMSI")..","..get("IMEI")..","..get("FACID")
	end
	local function locrpt()
		local g = get("GPS")
		return g.state..","..g.lngflg..","..g.lng..","..g.latflg..","..g.lat..","..g.spd..","..g.cog..","..get("STATUS")..","..get("CELLINFO")..","..get("SATSIGBAT")
	end
	local function heart()
		return get("SATSIGBAT")
	end
	local function setrsp(typ,result)
		return typ..","..result
	end
	local function guardrsp(result)
		return result
	end
	local function qrylocrsp()
		local g = get("GPS")
		return g.state..","..g.lngflg..","..g.lng..","..g.latflg..","..g.lat..","..g.spd..","..g.cog..","..get("STATUS")..","..get("CELLINFO")
	end
	local function qrypararsp(val)
		return val
	end
	local procer = {
		[LOGIN] = login,
		[LOCRPT] = locrpt,
		[HEART] = heart,
		[SETRSP] = setrsp,
		[GUARDONRSP] = guardrsp,
		[GUARDOFFRSP] = guardrsp,
		[QRYLOCRSP] = qrylocrsp,
		[QRYPARARSP] = qrypararsp,
	}
	local s = head..procer[id](...)..tail
	return s
end
function unpack(s)
	local packet = {}
	local function loginrsp(d)
		if slen(d) ~= 1 then return end
		local cmd = tonumber(d)+1
		local t = {
			"EXPIRED","OK","NOMATCH","UNADD"
		}
		if not t[cmd] then return end
		packet.response = t[cmd]
		return true
	end
	local function set(d)
		if slen(d) == 0 then return end
		local t,v = smatch(d,"(%w+)=(.+)")
		if not t or not v then return end
		packet.typ,packet.val = t,v
		return true
	end
	local function dummy(d)
		if slen(d) ~= 0 then return end
		return true
	end
	local function qrypara(d)
		if slen(d) == 0 then return end		
		packet.typ = d
		return true
	end
	local procer = {
		[LOGINRSP] = loginrsp,
		[SET] = set,
		[LOCRPTRSP] = dummy,
		[QRYLOC] = dummy,
		[HEARTRSP] = dummy,
		[RESTART] = dummy,
		[GUARDON] = dummy,
		[GUARDOFF] = dummy,
		[QRYPARA] = qrypara,
	}
	local _,d1,tm,id = sfind(s,"%[([%d %-:]*),(%w+)")
	if not id or not procer[id] then print("protorx.unpack:unknwon id",id) return end
	_,d2 = sfind(s,"%]")
	s = ssub(s,d1+2,d2-1) or ""
	packet.id = id
	packet.tm = tm
	return procer[id](s) and packet or nil
end
function reget(id)
	get = id
end
