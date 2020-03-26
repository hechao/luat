
module(...,package.seeall)
local link = require"link"
local misc = require"misc"
local FREQ,prot,addr,port,lid,linksta = 1800000
--luaerr："/luaerrinfo.txt"中的错误信息
local DBG_FILE,inf,luaerr,d1,d2 = "/dbg.txt",""

local function readtxt(f)
	local file,rt = io.open(f,"r")
	if file == nil then
		print("dbg can not open file",f)
		return ""
	end
	rt = file:read("*a")
	file:close()
	return rt or ""
end

local function writetxt(f,v)
	local file = io.open(f,"w")
	if file == nil then
		print("dbg open file to write err",f)
		return
	end
	file:write(v)
	file:close()
end

local function writerr(append,s)	
	print("dbg_w",append,s)
	if s then
		local str = (append and (readtxt(DBG_FILE)..s) or s)
		if string.len(str)<900 then
			writetxt(DBG_FILE,str)
		end
	end
end

local function initerr()
	inf = (sys.getextliberr() or "")..(readtxt(DBG_FILE) or "")
	print("dbg inf",inf)
end

local function getlasterr()
	luaerr = readtxt("/luaerrinfo.txt") or ""
end

local function valid()
	return ((string.len(luaerr) > 0) or (string.len(inf) > 0)) and _G.PROJECT
end

local function rcvtimeout()
	endntfy()
	link.close(lid)
end

local function snd()
	local data = (luaerr or "") .. (inf or "")
	if string.len(data) > 0 then
		link.send(lid,_G.PROJECT .."_"..sys.getcorever() .. "," .. (_G.VERSION and (_G.VERSION .. ",") or "") .. misc.getimei() .. "," .. data)
		sys.timer_start(snd,FREQ)
		sys.timer_start(rcvtimeout,20000)
	end
end
local reconntimes = 0

local function reconn()
	if reconntimes < 3 then
		reconntimes = reconntimes+1
		link.connect(lid,prot,addr,port)
	else
		endntfy()
	end
end

function endntfy()
	sys.dispatch("DBG_END_IND")
	sys.timer_stop(sys.dispatch,"DBG_END_IND")
end

local function notify(id,evt,val)
	print("dbg notify",id,evt,val)
	if id ~= lid then return end
	if evt == "CONNECT" then
		if val == "CONNECT OK" then
			linksta = true
			sys.timer_stop(reconn)
			reconntimes = 0
			snd()
		else
			sys.timer_start(reconn,5000)
		end
	elseif evt=="DISCONNECT" or evt=="CLOSE" then
		linksta = false
	elseif evt == "STATE" and val == "CLOSED" then
		link.close(lid)
	end
end

local function recv(id,data)
	if string.upper(data) == "OK" then
		sys.timer_stop(snd)
		link.close(lid)
		inf = ""
		writerr(false,"")
		luaerr = ""
		os.remove("/luaerrinfo.txt")
		endntfy()
		sys.timer_stop(rcvtimeout)
	end
end

local function init()
	initerr()
	getlasterr()
	if valid() then
		if linksta then
			snd()
		else
			lid = link.open(notify,recv,"dbg")
			link.connect(lid,prot,addr,port)
		end
		sys.dispatch("DBG_BEGIN_IND")
		sys.timer_start(sys.dispatch,120000,"DBG_END_IND")
	end
end

function restart(r)
	writerr(true,"RST:" .. (r or "") .. ";")
	rtos.restart()
end

function saverr(s)
	writerr(true,s)
end

function setup(inProt,inAddr,inPort)
	if inProt and inAddr and inPort then
		prot,addr,port = inProt,inAddr,inPort
		init()
	end
end
